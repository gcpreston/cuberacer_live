defmodule CuberacerLiveWeb.RoomController do
  use CuberacerLiveWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
