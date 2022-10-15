defmodule CuberacerLiveWeb.UserProfileController do
  use CuberacerLiveWeb, :controller

  alias CuberacerLive.{Accounts, Sessions}
  alias CuberacerLive.Accounts.User

  def show(conn, %{"id" => user_id}) do
    user = Accounts.get_user!(user_id)

    visible_sessions =
      Sessions.list_user_sessions(user)
      |> filter_sessions(user, conn.assigns.current_user)

    render(conn, "show.html", user: user, visible_sessions: visible_sessions)
  end

  defp filter_sessions(sessions, %User{id: user_id}, %User{id: current_user_id}) do
    Enum.filter(sessions, fn s ->
      if user_id == current_user_id do
        true
      else
        not Sessions.private?(s)
      end
    end)
  end
end
