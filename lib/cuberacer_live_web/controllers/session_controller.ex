defmodule CuberacerLiveWeb.SessionController do
  use CuberacerLiveWeb, :controller

  alias CuberacerLive.Sessions

  def show(conn, %{"id" => session_id}) do
    session = Sessions.get_loaded_session!(session_id)
    render(conn, "show.html", session: session)
  end
end
