defmodule CuberacerLiveWeb.RoomController do
  use CuberacerLiveWeb, :controller

  alias CuberacerLive.Sessions

  def show(conn, %{"id" => session_id}) do
    if not Sessions.session_is_active?(session_id) do
      conn
      |> put_flash(:error, "Session is inactive")
      |> redirect(to: Routes.game_lobby_path(conn, :index))
    else
      render(conn, "show.html")
    end
  end
end
