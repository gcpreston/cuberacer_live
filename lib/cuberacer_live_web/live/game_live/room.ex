defmodule CuberacerLiveWeb.GameLive.Room do
  use CuberacerLiveWeb, :live_view

  import CuberacerLive.Repo, only: [preload: 2]
  import CuberacerLiveWeb.SharedComponents, only: [rounds_table: 1]
  import CuberacerLiveWeb.GameLive.Components

  alias CuberacerLive.{Sessions, Accounts, Messaging}
  alias CuberacerLiveWeb.Presence

  @endpoint CuberacerLiveWeb.Endpoint
  @users_per_page 4

  @impl true
  def mount(%{"id" => session_id}, %{"user_token" => user_token}, socket) do
    user = user_token && Accounts.get_user_by_session_token(user_token)

    socket =
      cond do
        user == nil ->
          redirect(socket, to: Routes.user_session_path(@endpoint, :new))

        not Sessions.session_is_active?(session_id) ->
          socket
          |> put_flash(:error, "Session is inactive")
          |> push_redirect(to: Routes.game_lobby_path(socket, :index))

        true ->
          if connected?(socket) do
            track_presence(session_id, user.id)
            Sessions.subscribe(session_id)
            Messaging.subscribe(session_id)
          end

          socket
          |> assign(:current_user, user)
          |> fetch_session(session_id)
          |> fetch_present_users()
          |> set_users_page()
          |> fetch_rounds()
          |> fetch_has_current_solve?()
          |> fetch_stats()
          |> fetch_room_messages()
      end

    {:ok, socket, temporary_assigns: [rounds: [], room_messages: []]}
  end

  @impl true
  def mount(_params, _session, socket) do
    # TODO: How to make it redirect to room after login instead of /?
    {:ok,
     socket
     |> redirect(to: Routes.user_session_path(@endpoint, :new))}
  end

  ## Socket populators

  defp fetch_session(socket, session_id) do
    session = Sessions.get_session!(session_id)
    assign(socket, %{session_id: session_id, session: session})
  end

  defp fetch_rounds(socket) do
    rounds = Sessions.list_rounds_of_session(socket.assigns.session, :desc)
    assign(socket, rounds: rounds)
  end

  defp fetch_has_current_solve?(socket) do
    %{session: session, current_user: user} = socket.assigns
    has_current_solve? = Sessions.get_current_solve(session, user) != nil
    assign(socket, has_current_solve?: has_current_solve?)
  end

  defp fetch_stats(socket) do
    %{session: session, current_user: user} = socket.assigns
    stats = Sessions.current_stats(session, user)
    assign(socket, stats: stats)
  end

  defp fetch_present_users(socket) do
    present_users =
      for {_user_id_str, info} <- Presence.list(presence_topic(socket.assigns.session_id)) do
        info.user
      end

    assign(socket, :present_users, present_users)
  end

  # Must be called after fetch_present_users
  defp set_users_page(socket) do
    if Map.has_key?(socket.assigns, :users_page) do
      update(socket, :users_page, fn current_page ->
        if current_page > num_users_pages(length(socket.assigns.present_users)) do
          current_page - 1
        else
          current_page
        end
      end)
    else
      assign(socket, :users_page, 1)
    end
  end

  defp fetch_room_messages(socket) do
    room_messages = Messaging.list_room_messages(socket.assigns.session)
    assign(socket, room_messages: room_messages)
  end

  ## LiveView handlers

  @impl true
  def handle_event("new-round", _value, socket) do
    Sessions.create_round(socket.assigns.session)

    {:noreply, socket}
  end

  def handle_event("new-solve", %{"time" => time}, socket) do
    Sessions.create_solve(socket.assigns.session, socket.assigns.current_user, time, :OK)

    {:noreply,
     socket
     |> assign(:has_current_solve?, true)
     |> fetch_stats()}
  end

  def handle_event("change-penalty", %{"penalty" => penalty}, socket) do
    # TODO: Does this need to pass an atom?
    if solve = Sessions.get_current_solve(socket.assigns.session, socket.assigns.current_user) do
      Sessions.change_penalty(solve, penalty)
    end

    {:noreply, socket |> fetch_stats()}
  end

  def handle_event("send-message", %{"message" => message}, socket) do
    Messaging.create_room_message(socket.assigns.session, socket.assigns.current_user, message)

    {:noreply, socket}
  end

  def handle_event("send-message", _value, socket) do
    {:noreply, socket}
  end

  def handle_event("users-page-left", _value, socket) do
    {:noreply,
     update(socket, :users_page, fn current_page ->
       if current_page > 1 do
         current_page - 1
       else
         current_page
       end
     end)}
  end

  def handle_event("users-page-right", _value, socket) do
    {:noreply,
     update(socket, :users_page, fn current_page ->
       if current_page < num_users_pages(length(socket.assigns.present_users)) do
         current_page + 1
       else
         current_page
       end
     end)}
  end

  ## PubSub handlers

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, socket |> fetch_present_users() |> set_users_page() |> fetch_rounds()}
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
      |> update(:rounds, fn rounds -> [round | rounds] end)
      |> assign(:has_current_solve?, false)

    {:noreply, socket}
  end

  def handle_info({Sessions, [:solve, _action_type], solve}, socket) do
    # The round preload should do nothing because notify_subscribers for solves
    # already handles it.
    # It will stay though in order to not rely on that function's implementation.
    solve = preload(solve, :round)
    round = preload(solve.round, :solves)
    {:noreply, update(socket, :rounds, fn rounds -> [round | rounds] end)}
  end

  def handle_info({Messaging, [:room_message, _], room_message}, socket) do
    room_message = preload(room_message, :user)
    {:noreply, update(socket, :room_messages, fn msgs -> [room_message | msgs] end)}
  end

  ## Helpers

  defp presence_topic(session_id) do
    "room:" <> session_id
  end

  defp track_presence(session_id, user_id) do
    topic = presence_topic(session_id)
    CuberacerLiveWeb.Endpoint.subscribe(topic)
    Presence.track(self(), topic, user_id, %{})
  end

  defp current_scramble([current_round | _rest]) do
    current_round.scramble
  end

  defp current_scramble([]) do
    nil
  end

  defp scramble_text_size(scramble) do
    len = String.length(scramble)

    cond do
      len > 325 -> "text-sm lg:text-base"
      len > 225 -> "text-base lg:text-lg"
      true -> "text-lg"
    end
  end

  defp num_users_pages(num_present_users) do
    extra = if rem(num_present_users, @users_per_page) == 0, do: 0, else: 1
    div(num_present_users, @users_per_page) + extra
  end

  defp displayed_users(present_users, users_page) do
    Enum.slice(present_users, (users_page - 1) * @users_per_page, @users_per_page)
  end
end
