defmodule CuberacerLiveWeb.PageControllerTest do
  use CuberacerLiveWeb.ConnCase, async: true

  import CuberacerLive.AccountsFixtures

  describe "GET /" do
    test "renders splash page", %{conn: conn} do
      conn = get(conn, "/")
      assert html = html_response(conn, 200)

      html
      |> assert_html("h1", text: "Cuberacer")
      |> assert_html("a:nth-child(1)", text: "Log in")
      |> assert_html("a:nth-child(2)", text: "Sign up")
    end

    test "redirects if logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get("/")
      assert redirected_to(conn) == "/lobby"
    end
  end
end
