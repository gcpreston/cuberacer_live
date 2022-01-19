defmodule CuberacerLiveWeb.UserSessionController do
  use CuberacerLiveWeb, :controller

  alias CuberacerLive.Accounts
  alias CuberacerLiveWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"username_or_email" => username_or_email, "password" => password} = user_params

    user =
      if String.contains?(username_or_email, "@") do
        Accounts.get_user_by_email_and_password(username_or_email, password)
      else
        Accounts.get_user_by_username_and_password(username_or_email, password)
      end

    if user do
      UserAuth.log_in_user(conn, user, user_params)
    else
      render(conn, "new.html", error_message: "Invalid credentials")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
