defmodule CuberacerLiveWeb.SessionController do
  use CuberacerLiveWeb, :controller

  alias CuberacerLive.Sessions

  def show(conn, %{"id" => id}) do
    session = Sessions.get_loaded_session!(id)
    render(conn, "show.html", session: session)
  end
end
