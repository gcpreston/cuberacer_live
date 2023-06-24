defmodule CuberacerLiveWeb.LobbyLive do
  use CuberacerLiveWeb, :live_view

  import CuberacerLiveWeb.Components

  alias CuberacerLiveWeb.Endpoint
  alias CuberacerLiveWeb.Presence
  alias CuberacerLive.{LobbyServer, Sessions, Accounts}
  alias CuberacerLive.Sessions.Session

  @game_lobby_topic "lobby"

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = user_token && Accounts.get_user_by_session_token(user_token)

    socket =
      if !user do
        redirect(socket, to: ~p"/login")
      else
        if connected?(socket) do
          Presence.track(self(), @game_lobby_topic, user.id, %{})

          Endpoint.subscribe(@game_lobby_topic)
          Sessions.subscribe()
        end

        socket
        |> assign(:current_user, user)
        |> fetch_rooms()
        |> fetch_user_count()
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Lobby")
    |> assign(:session, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Room")
    |> assign(:session, %Session{})
  end

  defp apply_action(socket, :join, %{"id" => session_id}) do
    # TODO: Handle errors
    session = Sessions.get_session!(session_id)

    socket
    |> assign(:page_title, "Join Room")
    |> assign(:session, session)
  end

  ## Socket populators

  defp fetch_rooms(socket) do
    participant_counts = LobbyServer.get_participant_counts()
    session_ids = Map.keys(participant_counts)
    rooms = Sessions.get_sessions(session_ids)

    assign(socket, rooms: rooms, participant_counts: participant_counts)
  end

  defp fetch_user_count(socket) do
    user_count = length(Map.keys(Presence.list(@game_lobby_topic)))
    assign(socket, :user_count, user_count)
  end

  ## LiveView handlers

  @impl true
  def handle_event("join-room", %{"session_id" => session_id}, socket) do
    # TODO: Error handling, maybe not necessary to pass whole session...
    session = Sessions.get_session!(session_id)
    user = socket.assigns.current_user

    socket =
      if Accounts.user_authorized_for_room?(user, session) do
        push_navigate(socket, to: ~p"/rooms/#{session.id}")
      else
        push_patch(socket, to: ~p"/lobby/join/#{session.id}")
      end

    {:noreply, socket}
  end

  ## PubSub handlers

  @impl true
  def handle_info({CuberacerLive.PresenceClient, _}, socket) do
    {:noreply, fetch_user_count(socket)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, socket}
  end

  def handle_info(:fetch, socket) do
    {:noreply, fetch_rooms(socket)}
  end

  def handle_info({Sessions, %_event{session: _session}}, socket) do
    {:noreply, fetch_rooms(socket)}
  end
end
