defmodule CuberacerLiveWeb.GameLive.Room do
  use CuberacerLiveWeb, :live_view

  import CuberacerLive.Repo, only: [preload: 2]
  import CuberacerLiveWeb.GameLive.Components

  alias CuberacerLive.{RoomServer, Sessions, Accounts, Messaging}
  alias CuberacerLiveWeb.{Presence, Endpoint}

  @impl true
  def mount(%{"id" => session_id}, %{"user_token" => user_token}, socket) do
    case Integer.parse(session_id) do
      {session_id, ""} ->
        build_socket(session_id, user_token, socket)

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Invalid room ID")
         |> push_redirect(to: Routes.game_lobby_path(socket, :index))}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    # TODO: How to make it redirect to room after login instead of /?
    {:ok,
     socket
     |> redirect(to: Routes.user_session_path(socket, :new))}
  end

  defp build_socket(session_id, user_token, socket) when is_integer(session_id) do
    user = user_token && Accounts.get_user_by_session_token(user_token)

    socket =
      cond do
        user == nil ->
          redirect(socket, to: Routes.user_session_path(socket, :new))

        !RoomServer.whereis(session_id) ->
          socket
          |> put_flash(:error, "Room is inactive")
          |> push_redirect(to: Routes.game_lobby_path(socket, :index))

        true ->
          if connected?(socket) do
            track_presence(session_id, user.id)
            Endpoint.subscribe(pubsub_topic(session_id))
            Sessions.subscribe(session_id)
            Messaging.subscribe(session_id)
          end

          socket
          |> assign(:current_user, user)
          |> fetch_room_server_pid(session_id)
          |> fetch_session(session_id)
          |> fetch_participant_data()
          |> fetch_rounds()
          |> fetch_current_solve()
          |> fetch_stats()
          |> fetch_room_messages()
          |> initialize_time_entry()
      end

    {:ok, socket, temporary_assigns: [past_rounds: [], room_messages: []]}
  end

  ## Socket populators

  defp fetch_room_server_pid(socket, session_id) do
    pid = RoomServer.whereis(session_id)
    assign(socket, :room_server_pid, pid)
  end

  defp fetch_session(socket, session_id) do
    session = Sessions.get_session!(session_id)
    assign(socket, %{session_id: session_id, session: session})
  end

  defp fetch_rounds(socket) do
    [current_round | past_rounds] = Sessions.list_rounds_of_session(socket.assigns.session, :desc)
    assign(socket, current_round: current_round, past_rounds: past_rounds)
  end

  defp fetch_current_solve(socket) do
    %{session: session, current_user: user} = socket.assigns
    current_solve = Sessions.get_current_solve(session, user)
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
    assign(socket, room_messages: room_messages)
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
    Phoenix.PubSub.broadcast!(
      CuberacerLive.PubSub,
      room_server_topic(socket.assigns.session_id),
      {:solving, socket.assigns.current_user.id}
    )

    {:noreply, socket}
  end

  def handle_event("toggle-timer", _value, socket) do
    new_entry_method = if socket.assigns.time_entry == :timer, do: :keyboard, else: :timer

    Phoenix.PubSub.broadcast!(
      CuberacerLive.PubSub,
      room_server_topic(socket.assigns.session_id),
      {:set_time_entry, socket.assigns.current_user.id, new_entry_method}
    )

    {:noreply, assign(socket, :time_entry, new_entry_method)}
  end

  def handle_event("timer-submit", %{"time" => time}, socket) do
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
  end

  def handle_event("keyboard-submit", %{"keyboard_input" => %{"time" => time}}, socket) do
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
  def handle_info({:fetch, :participant_data}, socket) do
    {:noreply, socket |> fetch_participant_data()}
  end

  def handle_info({:fetch, :participants}, socket) do
    {:noreply, socket |> fetch_participant_data() |> fetch_rounds()}
  end

  def handle_info({:set_time_entry, _user_id, _method}, socket) do
    {:noreply, socket |> fetch_participant_data()}
  end

  def handle_info({Sessions, [:session, :updated], session}, socket) do
    {:noreply, assign(socket, session: session)}
  end

  def handle_info({Sessions, [:session, :deleted], _session}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Session was deleted")
     |> push_redirect(to: Routes.game_lobby_path(socket, :index))}
  end

  # TODO: I don't like having a Repo call in this file, and would like to
  # have preload options in the context instead, but not sure what the best
  # way to specify preloads would be in this case where we aren't explicitly
  # fetching the solve... having a preload wrapper in the context seems
  # like a solution just for show

  def handle_info({Sessions, [:round, :created], round}, socket) do
    round = preload(round, :solves)

    socket =
      socket
      |> update(:past_rounds, fn rounds -> [socket.assigns.current_round | rounds] end)
      |> assign(:current_round, round)
      |> assign(:current_solve, nil)

    {:noreply, socket}
  end

  def handle_info({Sessions, [:solve, _action], solve}, socket) do
    # The round preload should do nothing because notify_subscribers for solves
    # already handles it.
    # It will stay though in order to not rely on that function's implementation.
    solve = preload(solve, :round)
    current_round = preload(solve.round, :solves)

    socket =
      socket
      |> assign(:current_round, current_round)
      |> fetch_participant_data()

    {:noreply, socket}
  end

  def handle_info({Messaging, [:room_message, _], room_message}, socket) do
    room_message = preload(room_message, :user)
    {:noreply, update(socket, :room_messages, fn msgs -> [room_message | msgs] end)}
  end

  ## Helpers

  defp pubsub_topic(session_id) do
    "room:#{session_id}"
  end

  defp room_server_topic(session_id) do
   "#{inspect(RoomServer)}:#{session_id}"
  end

  defp track_presence(session_id, user_id) do
    topic = room_server_topic(session_id)
    Presence.track(self(), topic, user_id, %{})
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
end
