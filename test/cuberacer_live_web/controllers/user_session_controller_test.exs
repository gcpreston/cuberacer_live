defmodule CuberacerLiveWeb.UserSessionControllerTest do
  use CuberacerLiveWeb.ConnCase, async: true

  import CuberacerLive.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /login" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, ~p"/login")
      response = html_response(conn, 200)
      assert response =~ "Log in to Cuberacer</h1>"
      assert response =~ "Log in</button>"
      assert response =~ "Sign up"
      assert response =~ "Forgot password?"
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> get(~p"/login")
      assert redirected_to(conn) == "/lobby"
    end
  end

  describe "POST /login" do
    test "logs the user in via username", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/login", %{
          "user" => %{"username_or_email" => user.username, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/lobby"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/users/settings")
      response = html_response(conn, 200)
      assert response =~ user.username
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "logs the user in via email", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/login", %{
          "user" => %{"username_or_email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/lobby"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/users/settings")
      response = html_response(conn, 200)
      assert response =~ user.username
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/login", %{
          "user" => %{
            "username_or_email" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_cuberacer_live_web_user_remember_me"]
      assert redirected_to(conn) == "/lobby"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(~p"/login", %{
          "user" => %{
            "username_or_email" => user.email,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/login", %{
          "user" => %{"username_or_email" => user.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "Log in to Cuberacer</h1>"
      assert response =~ "Invalid credentials"
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/users/log_out")
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/users/log_out")
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
