defmodule CuberacerLiveWeb.SessionController do
  use CuberacerLiveWeb, :controller

  alias CuberacerLive.{Sessions, Accounts}

  def show(conn, %{"id" => id}) do
    session = Sessions.get_loaded_session!(id)

    if Sessions.private?(session) &&
         !Accounts.user_authorized_for_room?(conn.assigns.current_user, session) do
      render_error(conn, 404)
    else
      render(conn, "show.html", session: session)
    end
  end

  defp render_error(conn, status_code) do
    conn
    |> put_view(CuberacerLiveWeb.ErrorView)
    |> put_status(status_code)
    |> render("#{status_code}.html")
  end
end
