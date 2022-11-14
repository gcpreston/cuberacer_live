defmodule CuberacerLiveWeb.UserProfileController do
  use CuberacerLiveWeb, :controller

  alias CuberacerLive.{Accounts, Sessions}

  def show(conn, %{"id" => user_id}) do
    user = Accounts.get_user!(user_id)
    visible_sessions = Sessions.list_visible_user_sessions(user, conn.assigns.current_user)

    render(conn, "show.html", user: user, visible_sessions: visible_sessions)
  end
end
