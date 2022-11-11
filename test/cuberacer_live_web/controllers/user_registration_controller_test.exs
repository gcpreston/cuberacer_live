defmodule CuberacerLiveWeb.UserRegistrationControllerTest do
  use CuberacerLiveWeb.ConnCase, async: true

  import CuberacerLive.AccountsFixtures

  describe "GET /signup" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, ~p"/signup")
      response = html_response(conn, 200)
      assert response =~ "Welcome</h1>"
      assert response =~ "Sign up</button>"
      assert response =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(~p"/signup")
      assert redirected_to(conn) == ~p"/lobby"
    end
  end

  describe "POST /signup" do
    @tag :capture_log
    test "creates account and logs the user in", %{conn: conn} do
      {email, username} = unique_email_and_username()

      conn =
        post(conn, ~p"/signup", %{
          "user" => valid_user_attributes(email: email, username: username)
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/lobby"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/lobby")
      response = html_response(conn, 200)
      assert response =~ username
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, ~p"/signup", %{
          "user" => %{"email" => "with spaces", "password" => "short"}
        })

      response = html_response(conn, 200)
      assert response =~ "Welcome</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 6 character"
    end
  end
end
