defmodule CuberacerLiveWeb.GameLive.Lobby do
  use CuberacerLiveWeb, :live_view

  import CuberacerLiveWeb.GameLive.Components

  alias CuberacerLiveWeb.Endpoint
  alias CuberacerLiveWeb.Presence
  alias CuberacerLive.{LobbyServer, Sessions, Accounts}
  alias CuberacerLive.Sessions.Session

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = user_token && Accounts.get_user_by_session_token(user_token)

    socket =
      if !user do
        redirect(socket, to: Routes.user_session_path(Endpoint, :new))
      else
        if connected?(socket) do
          track_presence(user.id)
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

  ## Socket populators

  defp fetch_rooms(socket) do
    participant_counts = LobbyServer.get_participant_counts()

    rooms =
      Sessions.get_sessions(Map.keys(participant_counts))
      |> Enum.filter(fn session ->
        not session.unlisted? or socket.assigns.current_user.id == session.host_id
      end)

    assign(socket, rooms: rooms, participant_counts: participant_counts)
  end

  defp fetch_user_count(socket) do
    user_count = length(Map.keys(Presence.list(pubsub_topic())))
    assign(socket, :user_count, user_count)
  end

  ## PubSub handlers

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, fetch_user_count(socket)}
  end

  def handle_info(:fetch, socket) do
    {:noreply, fetch_rooms(socket)}
  end

  def handle_info({Sessions, [:session | _], _}, socket) do
    {:noreply, fetch_rooms(socket)}
  end

  ## Helpers

  defp pubsub_topic do
    "lobby"
  end

  defp track_presence(user_id) do
    topic = pubsub_topic()
    Endpoint.subscribe(topic)
    Presence.track(self(), topic, user_id, %{})
  end
end
