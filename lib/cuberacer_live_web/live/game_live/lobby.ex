defmodule CuberacerLiveWeb.GameLive.Lobby do
  use CuberacerLiveWeb, :live_view

  alias CuberacerLive.Sessions

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Sessions.subscribe()
    {:ok, fetch(socket)}
  end

  defp fetch(socket) do
    active_rooms = CuberacerLive.RoomCache.list_active_rooms()
    assign(socket, active_rooms: active_rooms)
  end

  @impl true
  def handle_event("new-room", _value, socket) do
    RoomCache.create_room(%{name: "lobby session", cube_type_id: Cubing.get_cube_type("3x3").id})
    {:noreply, socket}
  end

  @impl true
  def handle_info({Sessions, [:session | _], _}, socket) do
    {:noreply, fetch(socket)}
  end
end
