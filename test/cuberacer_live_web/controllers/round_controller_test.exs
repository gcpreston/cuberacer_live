defmodule CuberacerLive.RoundControllerTest do
  use CuberacerLiveWeb.ConnCase, async: true

  import CuberacerLive.AccountsFixtures
  import CuberacerLive.CubingFixtures
  import CuberacerLive.SessionsFixtures

  alias CuberacerLive.Sessions
  alias CuberacerLiveWeb.SharedUtils

  setup do
    %{user: user_fixture(), round: round_fixture()}
  end

  describe "GET /rounds/:id" do
    test "empty case", %{conn: conn, user: user, round: round} do
      conn = conn |> log_in_user(user) |> get(Routes.round_path(conn, :show, round.id))
      html = html_response(conn, 200)

      assert html =~ "Round</h1>"
      assert html =~ SharedUtils.format_datetime(round.inserted_at)
      assert html =~ round.scramble
      assert html =~ "No solves"

      html
      |> assert_html("a[href='#{Routes.session_path(conn, :show, round.session_id)}']",
        text: round.session_id
      )
    end

    test "displays round data", %{conn: conn, user: user1, round: round} do
      user2 = user_fixture()
      user3 = user_fixture()
      penalty_plus2 = penalty_fixture(name: "+2")
      penalty_dnf = penalty_fixture(name: "DNF")
      solve1 = solve_fixture(round_id: round.id, user_id: user1.id, time: 1234)

      solve2 =
        solve_fixture(
          round_id: round.id,
          user_id: user2.id,
          time: 4321,
          penalty_id: penalty_plus2.id
        )

      solve3 =
        solve_fixture(
          round_id: round.id,
          user_id: user3.id,
          time: 3431,
          penalty_id: penalty_dnf.id
        )

      conn = conn |> log_in_user(user1) |> get(Routes.round_path(conn, :show, round.id))
      html = html_response(conn, 200)

      assert html =~ "Round</h1>"
      assert html =~ SharedUtils.format_datetime(round.inserted_at)
      assert html =~ round.scramble

      html
      |> assert_html("a[href='#{Routes.session_path(conn, :show, round.session_id)}']",
        text: round.session_id
      )
      |> assert_html("tr", count: 4)
      |> assert_html("tr td a[href='#{Routes.user_profile_path(conn, :show, solve1.user_id)}']",
        text: user1.username
      )
      |> assert_html("tr td a[href='#{Routes.user_profile_path(conn, :show, solve2.user_id)}']",
        text: user2.username
      )
      |> assert_html("tr td a[href='#{Routes.user_profile_path(conn, :show, solve3.user_id)}']",
        text: user3.username
      )
      |> assert_html("tr td a[href='#{Routes.solve_path(conn, :show, solve1.id)}']",
        text: Sessions.display_solve(solve1)
      )
      |> assert_html("tr td a[href='#{Routes.solve_path(conn, :show, solve2.id)}']",
        text: Sessions.display_solve(solve2)
      )
      |> assert_html("tr td a[href='#{Routes.solve_path(conn, :show, solve3.id)}']",
        text: Sessions.display_solve(solve3)
      )
    end

    test "redirects if not logged in", %{conn: conn, round: round} do
      conn = get(conn, Routes.round_path(conn, :show, round.id))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end
end
