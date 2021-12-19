defmodule CuberacerLiveWeb.GameLive.Room do
  use CuberacerLiveWeb, :live_view

  alias CuberacerLive.{Sessions, Cubing, Accounts}
  alias CuberacerLiveWeb.Presence

  @impl true
  def mount(%{"id" => session_id}, %{"user_token" => user_token}, socket) do
    user = user_token && Accounts.get_user_by_session_token(user_token)

    socket =
      if user == nil do
        redirect(socket, to: Routes.user_session_path(CuberacerLiveWeb.Endpoint, :new))
      else
        track_presence(session_id, user.id)

        socket
        |> assign(:user, user)
        |> fetch_session(session_id)
        |> fetch_rounds()
        |> fetch_solves()
        |> fetch_present_users()
      end

    {:ok, socket, temporary_assigns: [rounds: [], solves: []]}
  end

  @impl true
  def mount(_params, _session, socket) do
    # TODO: How to make it redirect to room after login instead of /?
    {:ok,
     socket
     |> redirect(to: Routes.user_session_path(CuberacerLiveWeb.Endpoint, :new))}
  end

  defp presence_topic(session_id) do
    "room:" <> session_id
  end

  defp track_presence(session_id, user_id) do
    topic = presence_topic(session_id)
    CuberacerLiveWeb.Endpoint.subscribe(topic)
    Presence.track(self(), topic, user_id, %{})
  end

  defp fetch_session(socket, session_id) do
    session = Sessions.get_session!(session_id)
    assign(socket, %{session_id: session_id, session: session})
  end

  defp fetch_rounds(socket) do
    rounds = Sessions.list_rounds_of_session(socket.assigns.session)
    current_round = Sessions.get_current_round(socket.assigns.session)
    assign(socket, %{current_round_id: current_round.id, rounds: rounds})
  end

  defp fetch_solves(socket) do
    solves = Sessions.list_solves_of_session(socket.assigns.session)
    assign(socket, :solves, solves)
  end

  defp fetch_present_users(socket) do
    present_users =
      for {_user_id_str, info} <- Presence.list(presence_topic(socket.assigns.session_id)) do
        info.user
      end

    assign(socket, :present_users, present_users)
  end

  @impl true
  def handle_event("new-round", _value, socket) do
    {:ok, round} = Sessions.create_round(%{session_id: socket.assigns.session_id})
    {:noreply, assign(socket, %{rounds: [round], current_round_id: round.id})}
  end

  @impl true
  def handle_event("new-solve", %{"time" => _time}, socket) do
    {:ok, solve} =
      Sessions.create_solve(
        socket.assigns.session,
        socket.assigns.user,
        :rand.uniform(100), # time,
        Cubing.get_penalty("OK")
      )

    {:noreply, assign(socket, :solves, [solve])}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, fetch_present_users(socket)}
  end

  @impl true
  def handle_info({Sessions, [:session, :updated], session}, socket) do
    {:noreply, assign(socket, session: session)}
  end

  @impl true
  def handle_info({Sessions, [:session, :deleted], _session}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Session was deleted")
     |> push_redirect(to: Routes.live_path(socket, CuberacerLiveWeb.GameLive.Lobby))}
  end

  @impl true
  def handle_info({Sessions, [:round, :created], round}, socket) do
    {:noreply, assign(socket, rounds: [round])}
  end

  @impl true
  def handle_info({Sessions, [:solve, :created], solve}, socket) do
    {:noreply, assign(socket, solves: [solve])}
  end
end
