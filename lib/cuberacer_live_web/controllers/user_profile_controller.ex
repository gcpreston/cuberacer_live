defmodule CuberacerLiveWeb.UserProfileController do
  use CuberacerLiveWeb, :controller

  alias CuberacerLive.Accounts

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.html", user: user)
  end
end
