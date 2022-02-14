defmodule CuberacerLive.SessionControllerTest do
  use CuberacerLiveWeb.ConnCase, async: true

  import CuberacerLive.AccountsFixtures
  import CuberacerLive.MessagingFixtures
  import CuberacerLive.SessionsFixtures

  alias CuberacerLive.Sessions
  alias CuberacerLiveWeb.SharedUtils

  setup do
    %{user: user_fixture(), session: session_fixture()}
  end

  describe "GET /sessions/:id" do
    test "empty case", %{conn: conn, user: user, session: session} do
      conn = conn |> log_in_user(user) |> get(Routes.session_path(conn, :show, session.id))
      html = html_response(conn, 200)

      assert html =~ "Session</h1>"
      assert html =~ SharedUtils.format_datetime(session.inserted_at)
      assert html =~ "Chat log"
      assert html =~ "No messages"
      assert_html(html, "tr", count: 1)
    end

    test "displays session data", %{conn: conn, user: user1, session: session} do
      user2 = user_fixture()
      user3 = user_fixture()

      _message1 = room_message_fixture(session: session, user: user1, message: "hey everyone")
      _message2 = room_message_fixture(session: session, user: user2, message: "hope this passes")

      round1 = round_fixture(session: session)
      round2 = round_fixture(session: session)
      round3 = round_fixture(session: session)
      solve1 = solve_fixture(round_id: round1.id, user_id: user1.id, time: 1234)

      solve2 =
        solve_fixture(
          round_id: round1.id,
          user_id: user2.id,
          time: 4321,
          penalty: :"+2"
        )

      solve3 = solve_fixture(round_id: round2.id, user_id: user1.id, time: 8431)
      solve4 = solve_fixture(round_id: round3.id, user_id: user3.id, time: 5013)

      solve5 =
        solve_fixture(
          round_id: round3.id,
          user_id: user2.id,
          time: 1351,
          penalty: :DNF
        )

      conn = conn |> log_in_user(user1) |> get(Routes.session_path(conn, :show, session.id))
      html = html_response(conn, 200)

      assert html =~ "Session</h1>"
      assert html =~ SharedUtils.format_datetime(session.inserted_at)
      assert html =~ "#{session.puzzle_type}"
      assert html =~ Calendar.strftime(session.inserted_at, "%c")
      assert html =~ "Chat log"
      assert html =~ "#{user1.username}: hey everyone"
      assert html =~ "#{user2.username}: hope this passes"

      html
      |> assert_html("tr td a[href='#{Routes.round_path(conn, :show, round1.id)}']",
        text: round1.scramble
      )
      |> assert_html("tr td a[href='#{Routes.round_path(conn, :show, round2.id)}']",
        text: round2.scramble
      )
      |> assert_html("tr td a[href='#{Routes.round_path(conn, :show, round3.id)}']",
        text: round3.scramble
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
      |> assert_html("tr td a[href='#{Routes.solve_path(conn, :show, solve4.id)}']",
        text: Sessions.display_solve(solve4)
      )
      |> assert_html("tr td a[href='#{Routes.solve_path(conn, :show, solve5.id)}']",
        text: Sessions.display_solve(solve5)
      )
    end

    test "redirects if not logged in", %{conn: conn, session: session} do
      conn = get(conn, Routes.session_path(conn, :show, session.id))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end
end
