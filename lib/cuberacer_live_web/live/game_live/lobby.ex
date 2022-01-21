defmodule CuberacerLiveWeb.GameLive.Lobby do
  use CuberacerLiveWeb, :live_view

  import CuberacerLiveWeb.GameLive.Components

  alias CuberacerLive.Sessions
  alias CuberacerLive.Sessions.Session

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Sessions.subscribe()
    {:ok, fetch(socket)}
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

  defp fetch(socket) do
    sessions = Sessions.list_active_sessions()
    assign(socket, active_sessions: sessions)
  end

  @impl true
  def handle_info({Sessions, [:session | _], _}, socket) do
    {:noreply, fetch(socket)}
  end
end
