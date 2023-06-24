defmodule CuberacerLiveWeb.RoomLive do
  use CuberacerLiveWeb, :live_view

  import CuberacerLive.Repo, only: [preload: 2]
  import CuberacerLiveWeb.Components

  alias CuberacerLive.ParticipantDataEntry
  alias CuberacerLive.{RoomServer, Sessions, Accounts, Messaging, Events}
  alias CuberacerLiveWeb.{Presence, Endpoint}

  @impl true
  def mount(%{"id" => session_id}, %{"user_token" => user_token}, socket)
      when not is_nil(user_token) do
    session = Sessions.get_session(session_id)
    user = Accounts.get_user_by_session_token(user_token)

    socket =
      cond do
        user == nil ->
          redirect(socket, to: ~p"/login")

        session == nil ->
          push_navigate_to_lobby(socket, "Unknown room")

        !RoomServer.whereis(session.id) ->
          push_navigate_to_lobby(socket, "Room has terminated")

        !Accounts.user_authorized_for_room?(user, session) ->
          push_navigate_to_room_join(socket, session)

        true ->
          track_and_subscribe(socket, user, session)
          socket_pipeline(socket, user, session)
      end

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    # TODO: How to make it redirect to room after login instead of /?
    {:ok,
     socket
     |> redirect(to: ~p"/login")}
  end

  defp push_navigate_to_lobby(socket, flash_error) do
    socket
    |> put_flash(:error, flash_error)
    |> push_navigate(to: ~p"/lobby")
  end

  defp push_navigate_to_room_join(socket, session) do
    socket
    |> push_navigate(to: ~p"/lobby/join/#{session.id}")
  end

  defp track_and_subscribe(socket, user, session) do
    if connected?(socket) do
      topic = game_room_topic(session.id)
      Endpoint.subscribe(topic)

      # Presence
      Presence.track(self(), topic, user.id, %{})

      # Application events
      Sessions.subscribe(session.id)
      Messaging.subscribe(session.id)
    end
  end

  defp socket_pipeline(socket, current_user, session) do
    socket
    |> assign(:session, session)
    |> assign(:current_user, current_user)
    |> fetch_room_server_pid(session.id)
    |> fetch_participant_data()
    |> fetch_rounds()
    |> fetch_current_solve()
    |> fetch_stats()
    |> fetch_room_messages()
    |> initialize_time_entry()
  end

  ## Socket populators

  defp fetch_room_server_pid(socket, session_id) do
    pid = RoomServer.whereis(session_id)
    assign(socket, :room_server_pid, pid)
  end

  defp fetch_rounds(socket) do
    rounds = Sessions.list_rounds_of_session(socket.assigns.session, :desc)
    assign(socket, all_rounds: rounds)
  end

  defp fetch_current_solve(socket) do
    %{current_user: user, all_rounds: rounds} = socket.assigns
    current_round = hd(rounds)
    current_solve = Enum.find(current_round.solves, fn solve -> solve.user_id == user.id end)
    assign(socket, current_solve: current_solve)
  end

  defp fetch_stats(socket) do
    %{session: session, current_user: user} = socket.assigns
    stats = Sessions.current_stats(session, user)
    assign(socket, stats: stats)
  end

  defp fetch_participant_data(socket) do
    participant_data = RoomServer.get_participant_data(socket.assigns.room_server_pid)
    assign(socket, :participant_data, participant_data)
  end

  defp fetch_room_messages(socket) do
    room_messages = Messaging.list_room_messages(socket.assigns.session)
    stream(socket, :room_messages, room_messages)
  end

  defp initialize_time_entry(socket) do
    assign(socket, time_entry: :timer)
  end

  ## LiveView handlers

  @impl true
  def handle_event("new-round", _value, socket) do
    RoomServer.create_round(socket.assigns.room_server_pid)

    {:noreply, socket}
  end

  def handle_event("solving", _value, socket) do
    Phoenix.PubSub.broadcast(
      CuberacerLive.PubSub,
      game_room_topic(socket.assigns.session.id),
      {:solving, socket.assigns.current_user.id}
    )

    {:noreply, socket}
  end

  def handle_event("toggle-timer", _value, socket) do
    new_entry_method = if socket.assigns.time_entry == :timer, do: :keyboard, else: :timer

    Phoenix.PubSub.broadcast(
      CuberacerLive.PubSub,
      game_room_topic(socket.assigns.session.id),
      {:set_time_entry, socket.assigns.current_user.id, new_entry_method}
    )

    {:noreply, assign(socket, :time_entry, new_entry_method)}
  end

  def handle_event("timer-submit", %{"time" => time}, socket) do
    if socket.assigns.current_solve == nil do
      solve =
        RoomServer.create_solve(
          socket.assigns.room_server_pid,
          socket.assigns.current_user,
          time,
          :OK
        )

      {:noreply,
       socket
       |> assign(:current_solve, solve)
       |> fetch_stats()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("keyboard-submit", %{"time" => time}, socket) do
    time_pattern = ~r/^(\d{1,2}:)?\d{1,2}(\.\d{0,3})?$/

    if Regex.match?(time_pattern, time) && !socket.assigns.current_solve do
      ms = keyboard_input_to_ms(time)

      solve =
        RoomServer.create_solve(
          socket.assigns.room_server_pid,
          socket.assigns.current_user,
          ms,
          :OK
        )

      {:noreply,
       socket
       |> assign(:current_solve, solve)
       |> fetch_stats()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("change-penalty", %{"penalty" => penalty}, socket) do
    RoomServer.change_penalty(
      socket.assigns.room_server_pid,
      socket.assigns.current_user,
      penalty
    )

    {:noreply, socket |> fetch_stats()}
  end

  def handle_event("send-message", %{"message" => message}, socket) do
    RoomServer.send_message(socket.assigns.room_server_pid, socket.assigns.current_user, message)

    {:noreply, socket}
  end

  def handle_event("send-message", _value, socket) do
    {:noreply, socket}
  end

  ## PubSub handlers

  @impl true
  def handle_info({:solving, user_id}, socket) do
    new_entry = ParticipantDataEntry.set_solving(socket.assigns.participant_data[user_id], true)
    {:noreply, update(socket, :participant_data, fn pd -> Map.put(pd, user_id, new_entry) end)}
  end

  def handle_info({:set_time_entry, user_id, new_method}, socket) do
    new_entry =
      ParticipantDataEntry.set_time_entry(socket.assigns.participant_data[user_id], new_method)

    {:noreply,
     socket
     |> update(:participant_data, fn pd -> Map.put(pd, user_id, new_entry) end)
     |> update(:time_entry, fn old_method ->
       if user_id == socket.assigns.current_user.id, do: new_method, else: old_method
     end)}
  end

  def handle_info({CuberacerLive.PresenceClient, {:join, user_data}}, socket) do
    entry = ParticipantDataEntry.new(user_data.user)
    {:noreply, update(socket, :participant_data, fn pd -> Map.put(pd, entry.user.id, entry) end)}
  end

  def handle_info({CuberacerLive.PresenceClient, {:leave, user_data}}, socket) do
    {:noreply, update(socket, :participant_data, fn pd -> Map.delete(pd, user_data.user.id) end)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, socket}
  end

  def handle_info({Sessions, %Events.SessionUpdated{session: session}}, socket) do
    {:noreply, assign(socket, session: session)}
  end

  def handle_info({Sessions, %Events.SessionDeleted{}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Session was deleted")
     |> push_navigate(to: ~p"/lobby")}
  end

  # TODO: I don't like having a Repo call in this file, and would like to
  # have preload options in the context instead, but not sure what the best
  # way to specify preloads would be in this case where we aren't explicitly
  # fetching the solve... having a preload wrapper in the context seems
  # like a solution just for show

  def handle_info({Sessions, %Events.RoundCreated{round: round}}, socket) do
    round = preload(round, :solves)

    socket =
      socket
      |> assign(:current_solve, nil)
      |> update(:all_rounds, fn rounds -> [round | rounds] end)

    for user_id <- Map.keys(socket.assigns.participant_data) do
      send_update(
        CuberacerLiveWeb.ParticipantComponent,
        id: "participant-component-#{user_id}",
        event: %Events.RoundCreated{round: round}
      )
    end

    {:noreply, socket}
  end

  def handle_info({Sessions, %_event{solve: solve} = event}, socket) do
    updated_round = Sessions.get_round!(solve.round_id) |> preload(:solves)

    socket =
      socket
      |> fetch_participant_data()
      |> update(:all_rounds, fn rounds -> find_and_update(rounds, updated_round) end)
      |> maybe_assign_current_solve(updated_round)

    send_update(
      CuberacerLiveWeb.ParticipantComponent,
      id: "participant-component-#{solve.user_id}",
      event: event
    )

    {:noreply, socket}
  end

  def handle_info({Messaging, %Events.RoomMessageCreated{room_message: room_message}}, socket) do
    room_message = preload(room_message, :user)

    {:noreply,
     if room_message.user_id != socket.assigns.current_user.id do
       push_event(socket, "unread-chat", %{id: room_message.id})
     else
       socket
     end
     |> stream_insert(:room_messages, room_message)}
  end

  ## Helpers

  defp game_room_topic(session_id) do
    "room:#{session_id}"
  end

  defp scramble_text_size(scramble) do
    len = String.length(scramble)

    cond do
      len > 325 -> "text-sm lg:text-base"
      len > 225 -> "text-base lg:text-lg"
      true -> "text-lg"
    end
  end

  defp keyboard_input_to_ms(input) do
    if String.contains?(input, ":") do
      [minutes_str, rest] = String.split(input, ":")
      {minutes, ""} = Integer.parse(minutes_str)
      {sec, ""} = Float.parse(rest)
      trunc((minutes * 60 + sec) * 1000)
    else
      {sec, _rest} = Float.parse(input)
      trunc(sec * 1000)
    end
  end

  defp find_and_update([], _item) do
    []
  end

  defp find_and_update([item | rest], %{id: updated_item_id} = updated_item) do
    if item.id == updated_item_id do
      [updated_item | rest]
    else
      [item | find_and_update(rest, updated_item)]
    end
  end

  defp maybe_assign_current_solve(socket, updated_round) do
    if updated_round.id == hd(socket.assigns.all_rounds).id do
      fetch_current_solve(socket)
    else
      socket
    end
  end
end
