defmodule CuberacerLiveWeb.UserProfileController do
  use CuberacerLiveWeb, :controller

  alias CuberacerLive.Accounts

  def show(conn, %{"id" => user_id}) do
    user = Accounts.get_user!(user_id)
    render(conn, "show.html", user: user)
  end
end
