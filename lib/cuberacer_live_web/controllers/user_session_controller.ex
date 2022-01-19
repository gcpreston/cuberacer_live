defmodule CuberacerLiveWeb.UserSessionController do
  use CuberacerLiveWeb, :controller

  alias CuberacerLive.Accounts
  alias CuberacerLiveWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"username_or_email" => username_or_email, "password" => password} = user_params

    cond do
      user = Accounts.get_user_by_username_and_password(username_or_email, password) ->
        UserAuth.log_in_user(conn, user, user_params)
      user = Accounts.get_user_by_email_and_password(username_or_email, password) ->
        UserAuth.log_in_user(conn, user, user_params)
      true ->
        # In order to prevent user enumeration attacks, don't disclose whether the username/email is registered.
        render(conn, "new.html", error_message: "Invalid credentials")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
