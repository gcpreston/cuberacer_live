defmodule CuberacerLive.RoundControllerTest do
  use CuberacerLiveWeb.ConnCase, async: true

  import CuberacerLive.AccountsFixtures
  import CuberacerLive.SessionsFixtures

  alias CuberacerLive.Sessions
  alias CuberacerLiveWeb.SharedUtils

  setup do
    %{user: user_fixture(), round: round_fixture()}
  end

  describe "GET /rounds/:id" do
    test "empty case", %{conn: conn, user: user, round: round} do
      session = Sessions.get_session!(round.session_id)
      conn = conn |> log_in_user(user) |> get(~p"/rounds/#{round.id}")
      html = html_response(conn, 200)

      assert html =~ "Round</h1>"
      assert html =~ SharedUtils.format_datetime(round.inserted_at)
      assert html =~ round.scramble
      assert html =~ "No solves"
      assert html =~ ~s(<a href="/sessions/#{session.id}">)
    end

    test "displays round data", %{conn: conn, user: user1, round: round} do
      user2 = user_fixture()
      user3 = user_fixture()
      solve1 = solve_fixture(round_id: round.id, user_id: user1.id, time: 1234)
      session = Sessions.get_session!(round.session_id)

      solve2 =
        solve_fixture(
          round_id: round.id,
          user_id: user2.id,
          time: 4321,
          penalty: :"+2"
        )

      solve3 =
        solve_fixture(
          round_id: round.id,
          user_id: user3.id,
          time: 3431,
          penalty: :DNF
        )

      conn = conn |> log_in_user(user1) |> get(~p"/rounds/#{round.id}")
      html = html_response(conn, 200)

      assert html =~ "Round</h1>"
      assert html =~ SharedUtils.format_datetime(round.inserted_at)
      assert html =~ round.scramble
      assert html =~ ~s(<a href="/sessions/#{session.id}">)

      html
      |> assert_html("tr", count: 4)
      |> assert_html("tr td a[href='#{~p"/users/#{solve1.user_id}"}']",
        text: user1.username
      )
      |> assert_html("tr td a[href='#{~p"/users/#{solve2.user_id}"}']",
        text: user2.username
      )
      |> assert_html("tr td a[href='#{~p"/users/#{solve3.user_id}"}']",
        text: user3.username
      )
      |> assert_html("tr td a[href='#{~p"/solves/#{solve1.id}"}']",
        text: Sessions.display_solve(solve1)
      )
      |> assert_html("tr td a[href='#{~p"/solves/#{solve2.id}"}']",
        text: Sessions.display_solve(solve2)
      )
      |> assert_html("tr td a[href='#{~p"/solves/#{solve3.id}"}']",
        text: Sessions.display_solve(solve3)
      )
    end

    test "redirects if not logged in", %{conn: conn, round: round} do
      conn = get(conn, ~p"/rounds/#{round.id}")
      assert redirected_to(conn) == ~p"/login"
    end
  end
end
