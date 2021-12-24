defmodule CuberacerLiveWeb.GameLive.Lobby do
  use CuberacerLiveWeb, :live_view

  alias CuberacerLive.Sessions

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Sessions.subscribe()
    {:ok, fetch(socket)}
  end

  defp fetch(socket) do
    # TODO: for now, every session is active
    sessions = Sessions.list_sessions()
    assign(socket, active_sessions: sessions)
  end

  @impl true
  def handle_info({Sessions, [:session | _], _}, socket) do
    {:noreply, fetch(socket)}
  end
end
