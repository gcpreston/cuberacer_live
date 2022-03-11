defmodule CuberacerLiveWeb.SolveControllerTest do
  use CuberacerLiveWeb.ConnCase, async: true

  import CuberacerLive.AccountsFixtures
  import CuberacerLive.SessionsFixtures

  alias CuberacerLive.Sessions
  alias CuberacerLiveWeb.SharedUtils

  setup do
    %{user: user_fixture(), solve: solve_fixture(penalty: :"+2")}
  end

  describe "GET /solves/:id" do
    test "displays solve data", %{conn: conn, user: user, solve: solve} do
      conn = conn |> log_in_user(user) |> get(Routes.solve_path(conn, :show, solve.id))
      html = html_response(conn, 200)

      solve = Sessions.get_loaded_solve!(solve.id)

      assert html =~ "Solve</h1>"
      assert html =~ SharedUtils.format_datetime(solve.inserted_at)
      assert html =~ solve.round.scramble
      assert html =~ Sessions.display_solve(solve)
      assert html =~ ~s(<a href="/sessions/#{Sessions.session_locator(solve.session)}">)

      html
      |> assert_html("a[href='#{Routes.user_profile_path(conn, :show, user.id)}']", text: user.username)
      |> assert_html("a[href='#{Routes.round_path(conn, :show, solve.round_id)}']", text: solve.round_id)
    end

    test "redirects if not logged in", %{conn: conn, solve: solve} do
      conn = get(conn, Routes.solve_path(conn, :show, solve.id))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end
end
