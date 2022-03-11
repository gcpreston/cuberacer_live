defmodule CuberacerLiveWeb.SessionController do
  use CuberacerLiveWeb, :controller

  alias CuberacerLive.Sessions

  def show(conn, %{"id" => locator}) do
    {used_session_id, session_id} = Sessions.parse_session_locator(locator)

    if is_nil(session_id) do
      render_error(conn, 404)
    else
      session = Sessions.get_loaded_session!(session_id)

      if session.unlisted? and used_session_id,
        do: render_error(conn, 404),
        else: render(conn, "show.html", session: session)
    end
  end

  defp render_error(conn, status_code) do
    conn
    |> put_view(CuberacerLiveWeb.ErrorView)
    |> put_status(status_code)
    |> render("#{status_code}.html")
  end
end
