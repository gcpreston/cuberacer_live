defmodule CuberacerLiveWeb.RoomChannel do
  use CuberacerLiveWeb, :channel

  alias CuberacerLive.Repo
  alias CuberacerLive.Sessions
  alias CuberacerLiveWeb.Presence

  @impl true
  def join("room:" <> room_id, payload, socket) do
    send(self(), :after_join)

    session = Sessions.get_room_data!(room_id)
    {:ok, session, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.user.id, %{
      online_at: inspect(System.system_time(:second))
    })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end
end
