defmodule CuberacerLiveWeb.GameLive.Room do
  use CuberacerLiveWeb, :live_view

  alias CuberacerLive.{Sessions, Cubing, Accounts}
  alias CuberacerLive.Sessions.Solve
  alias CuberacerLive.Accounts.User
  alias CuberacerLiveWeb.Presence

  @endpoint CuberacerLiveWeb.Endpoint

  @impl true
  def mount(%{"id" => session_id}, %{"user_token" => user_token}, socket) do
    user = user_token && Accounts.get_user_by_session_token(user_token)

    socket =
      if user == nil do
        redirect(socket, to: Routes.user_session_path(@endpoint, :new))
      else
        if connected?(socket) do
          track_presence(session_id, user.id)
          Sessions.subscribe(session_id)
        end

        socket
        |> assign(:user, user)
        |> fetch_session(session_id)
        |> fetch_present_users()
        |> fetch_rounds()
        |> fetch_solves()
      end

    {:ok, socket, temporary_assigns: [rounds: [], solves: []]}
  end

  @impl true
  def mount(_params, _session, socket) do
    # TODO: How to make it redirect to room after login instead of /?
    {:ok,
     socket
     |> redirect(to: Routes.user_session_path(@endpoint, :new))}
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
    assign(socket, rounds: rounds)
  end

  defp fetch_solves(socket) do
    solves =
      Sessions.list_solves_of_session(socket.assigns.session)
      |> Enum.map(&preload_solve/1)

    assign(socket, :solves, solves)
  end

  defp fetch_present_users(socket) do
    present_users =
      for {_user_id_str, info} <- Presence.list(presence_topic(socket.assigns.session_id)) do
        info.user
      end

    assign(socket, :present_users, present_users)
  end

  defp preload_solve(%Solve{} = solve) do
    CuberacerLive.Repo.preload(solve, [:user, :penalty])
  end

  defp solves_for(%User{} = user, solves) do
    Enum.filter(solves, &(&1.user_id == user.id))
  end

  @impl true
  def handle_event("new-round", _value, socket) do
    Sessions.create_round(%{session_id: socket.assigns.session_id})

    {:noreply, socket}
  end

  @impl true
  def handle_event("new-solve", %{"time" => time}, socket) do
    Sessions.create_solve(
      socket.assigns.session,
      socket.assigns.user,
      time,
      Cubing.get_penalty("OK")
    )

    {:noreply, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, socket |> fetch_present_users() |> fetch_solves()}
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
     |> push_redirect(to: Routes.game_lobby_path(socket, :index))}
  end

  @impl true
  def handle_info({Sessions, [:round, :created], round}, socket) do
    {:noreply, assign(socket, rounds: [round])}
  end

  @impl true
  def handle_info({Sessions, [:solve, :created], solve}, socket) do
    # TODO: I don't like having a Repo call in this file, and would like to
    # have preload options in the context instead, but not sure what the best
    # way to specify preloads would be in this case where we aren't explicitly
    # fetching the solve... having a preload wrapper in the context seems
    # like a solution just for show
    {:noreply, assign(socket, solves: [preload_solve(solve)])}
  end
end
