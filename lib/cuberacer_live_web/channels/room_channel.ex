defmodule CuberacerLiveWeb.RoomChannel do
  use CuberacerLiveWeb, :channel

  alias CuberacerLive.Repo
  alias CuberacerLive.Sessions

  @impl true
  def join("room:" <> room_id, payload, socket) do
    session = Sessions.get_room_data!(room_id)
    {:ok, session, socket}
  end

end
