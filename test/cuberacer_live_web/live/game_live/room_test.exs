defmodule CuberacerLiveWeb.GameLive.RoomTest do
  use CuberacerLiveWeb.ConnCase
  @moduletag ensure_presence_shutdown: true

  import Phoenix.LiveViewTest
  import Ecto.Query
  import CuberacerLive.AccountsFixtures
  import CuberacerLive.SessionsFixtures
  import CuberacerLive.MessagingFixtures

  alias CuberacerLive.{Repo, Sessions, Messaging}
  alias CuberacerLive.Sessions.Solve

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end

  defp create_session_and_round(_) do
    session = session_fixture()
    round = round_fixture(session: session)

    %{session: session, round: round}
  end

  defp authenticate(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end

  setup [:create_user, :create_session_and_round]

  describe "mount" do
    test "redirects if no user token", %{conn: conn, session: session} do
      login_path = Routes.user_session_path(conn, :new)

      assert {:error, {:redirect, %{to: ^login_path}}} =
               live(conn, Routes.game_room_path(conn, :show, session.id))
    end

    test "redirects if invalid user token", %{conn: conn, session: session} do
      login_path = Routes.user_session_path(conn, :new)
      conn = init_test_session(conn, %{user_token: "some invalid token"})

      assert {:error, {:redirect, %{to: ^login_path}}} =
               live(conn, Routes.game_room_path(conn, :show, session.id))
    end

    test "connects with valid user token", %{conn: conn, session: session, user: user} do
      conn = log_in_user(conn, user)

      assert {:ok, _view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))
      assert html =~ session.name
    end

    test "displays solves for user in room", %{
      conn: conn,
      session: session,
      round: round,
      user: user
    } do
      conn = log_in_user(conn, user)
      solve = solve_fixture(%{user_id: user.id, round_id: round.id})

      assert {:ok, _view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      html
      |> assert_html("th a", text: user.username)
      |> assert_html("#t_cell-round-#{round.id}-user-#{user.id}",
        text: Sessions.display_solve(solve)
      )
    end

    test "does not display solves for user not in room", %{
      conn: conn,
      session: session,
      round: round,
      user: user
    } do
      conn = log_in_user(conn, user)
      other_user = user_fixture()

      _solve = solve_fixture(%{user_id: other_user.id, round_id: round.id})

      assert {:ok, _view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))
      assert html =~ user.username
      refute html =~ other_user.username
    end

    test "displays messages in appropriate room", %{conn: conn, session: session1, user: user} do
      other_user = user_fixture()
      session2 = session_fixture()
      message1 = room_message_fixture(session: session1, user: user, message: "some text")
      message2 = room_message_fixture(session: session1, user: other_user)
      message3 = room_message_fixture(session: session2, user: user, message: "some other text")

      conn = log_in_user(conn, user)

      assert {:ok, _view, html} = live(conn, Routes.game_room_path(conn, :show, session1.id))

      html
      |> assert_html(".t_room-message", count: 2)

      assert html =~ Messaging.display_room_message(message1)
      assert html =~ Messaging.display_room_message(message2)
      refute html =~ Messaging.display_room_message(message3)
    end

    test "displays ao5 and ao12", %{conn: conn, session: session, user: user} do
      conn = log_in_user(conn, user)
      assert {:ok, _view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      html
      |> assert_html(".t_ao5", count: 1, text: "DNF")
      |> assert_html(".t_ao12", count: 1, text: "DNF")
    end

    test "displays green dot and empty timer if user does not have time for current round", %{
      conn: conn,
      session: session,
      user: user
    } do
      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      html
      |> assert_html("circle.fill-green-500", count: 1)
      |> refute_html("circle.fill-red-500")
    end

    test "displays red dot and time if user has a time for current round", %{
      conn: conn,
      session: session,
      round: round,
      user: user
    } do
      conn = log_in_user(conn, user)
      _solve = solve_fixture(time: 16_731, penalty: "+2", user_id: user.id, round_id: round.id)
      {:ok, _lv, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      html
      |> assert_html("circle.fill-red-500", count: 1)
      |> refute_html("circle.fill-green-500")
    end
  end

  describe "LiveView events" do
    setup [:authenticate]

    test "new-round creates a new round and handles race condition", %{
      conn: conn,
      session: session
    } do
      user2 = user_fixture()
      conn2 = Phoenix.ConnTest.build_conn() |> log_in_user(user2)
      {:ok, lv2, _html2} = live(conn2, Routes.game_room_path(conn2, :show, session.id))

      {:ok, lv1, html1} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_rounds_before = Enum.count(Sessions.list_rounds_of_session(session))

      assert_html(html1, "tr.t_round-row", count: num_rounds_before)

      # Wait out the debounce timer
      :timer.sleep(2000)

      render_click(lv1, "new-round")
      render_click(lv2, "new-round")

      num_rounds_after = Enum.count(Sessions.list_rounds_of_session(session))

      assert num_rounds_after == num_rounds_before + 1

      render(lv1)
      |> assert_html("tr.t_round-row", count: num_rounds_after)
      |> assert_html(".t_scramble", count: 1)
    end

    test "solving indicates that a user is solving", %{
      conn: conn,
      user: user,
      session: session,
      round: round
    } do
      other_user = user_fixture()
      other_conn = Phoenix.ConnTest.build_conn() |> log_in_user(other_user)

      {:ok, other_lv, _html} =
        live(other_conn, Routes.game_room_path(other_conn, :show, session.id))

      {:ok, lv, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      assert_html(html, "#t_cell-round-#{round.id}-user-#{user.id}", text: "--")

      render_hook(lv, "solving")

      render(lv)
      |> assert_html("#t_cell-round-#{round.id}-user-#{user.id}", text: "Solving...")

      render(other_lv)
      |> assert_html("#t_cell-round-#{round.id}-user-#{user.id}", text: "Solving...")
    end

    test "new-solve creates a new solve", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_solves_before = Enum.count(Sessions.list_solves_of_session(session))

      view
      |> render_hook("new-solve", time: 42)

      num_solves_after = Enum.count(Sessions.list_solves_of_session(session))

      newest_solve_query =
        from s in Solve,
          join: r in assoc(s, :round),
          where: r.session_id == ^session.id,
          order_by: [desc: s.inserted_at],
          limit: 1

      newest_solve = Repo.one(newest_solve_query)

      assert num_solves_after == num_solves_before + 1
      assert newest_solve.time == 42
      assert render(view) =~ Sessions.display_solve(newest_solve)
    end

    test "new-solve updates current stats", %{
      conn: conn,
      user: user,
      session: session,
      round: round1
    } do
      _solve1 = solve_fixture(round_id: round1.id, user_id: user.id)
      round2 = round_fixture(session: session)
      _solve2 = solve_fixture(round_id: round2.id, user_id: user.id)
      round3 = round_fixture(session: session)
      _solve3 = solve_fixture(round_id: round3.id, user_id: user.id)
      round4 = round_fixture(session: session)
      _solve4 = solve_fixture(round_id: round4.id, user_id: user.id)

      {:ok, live, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      assert_html(html, ".t_ao5", text: "DNF")

      _round5 = round_fixture(session: session)

      assert_html(render(live), ".t_ao5", text: "DNF")

      html =
        live
        |> render_hook("new-solve", time: 9876)

      stats = Sessions.current_stats(session, user)
      assert stats.ao5 != :dnf

      assert_html(html, ".t_ao5", text: Sessions.display_stat(stats.ao5))

      round6 = round_fixture(session: session)
      _solve6 = solve_fixture(round_id: round6.id, user_id: user.id)
      round7 = round_fixture(session: session)
      _solve7 = solve_fixture(round_id: round7.id, user_id: user.id)
      round8 = round_fixture(session: session)
      _solve8 = solve_fixture(round_id: round8.id, user_id: user.id)
      round9 = round_fixture(session: session)
      _solve9 = solve_fixture(round_id: round9.id, user_id: user.id)
      round10 = round_fixture(session: session)
      _solve10 = solve_fixture(round_id: round10.id, user_id: user.id)
      _round11 = round_fixture(session: session)

      html =
        live
        |> render_hook("new-solve", time: 6789)
        |> assert_html(".t_ao5", text: Sessions.display_stat(stats.ao5))

      stats = Sessions.current_stats(session, user)
      assert stats.ao5 != :dnf
      assert stats.ao12 == :dnf

      assert_html(html, ".t_ao12", text: "DNF")

      _round12 = round_fixture(session: session)

      html =
        live
        |> render_hook("new-solve", time: 9012)

      stats = Sessions.current_stats(session, user)
      assert stats.ao5 != :dnf
      assert stats.ao12 != :dnf

      html
      |> assert_html(".t_ao5", text: Sessions.display_stat(stats.ao5))
      |> assert_html(".t_ao12", text: Sessions.display_stat(stats.ao12))
    end

    test "change-penalty OK sets an OK penalty for the user's solve in the current round", %{
      conn: conn1,
      user: user1,
      session: session,
      round: round1
    } do
      user2 = user_fixture()
      solve1 = solve_fixture(time: 42, user_id: user1.id, round_id: round1.id)

      round2 = round_fixture(session: session)

      solve2 =
        solve_fixture(
          time: 43,
          penalty: :"+2",
          user_id: user1.id,
          round_id: round2.id
        )

      solve3 = solve_fixture(time: 44, user_id: user2.id, round_id: round2.id)

      conn2 = Phoenix.ConnTest.build_conn() |> log_in_user(user2)
      {:ok, _view2, _html2} = live(conn2, Routes.game_room_path(conn2, :show, session.id))
      {:ok, view, html} = live(conn1, Routes.game_room_path(conn1, :show, session.id))

      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve3)

      render_click(view, "change-penalty", %{"penalty" => "OK"})
      updated_solve2 = Sessions.get_solve!(solve2.id)
      html = render(view)

      assert updated_solve2.penalty == :OK
      assert html =~ Sessions.display_solve(updated_solve2)
      refute html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve3)
    end

    test "change-penalty OK does nothing if the user has no solve for the current round", %{
      conn: conn,
      user: user,
      session: session,
      round: round1
    } do
      solve = solve_fixture(penalty: :"+2", user_id: user.id, round_id: round1.id)
      _round2 = round_fixture(session: session)

      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)

      render_click(view, "change-penalty", %{"penalty" => "OK"})

      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)
    end

    test "change-penalty +2 sets a +2 penalty for the user's solve in the current round", %{
      conn: conn1,
      user: user1,
      session: session,
      round: round1
    } do
      user2 = user_fixture()
      solve1 = solve_fixture(time: 42, user_id: user1.id, round_id: round1.id)

      round2 = round_fixture(session: session)
      solve2 = solve_fixture(time: 43, user_id: user1.id, round_id: round2.id)
      solve3 = solve_fixture(time: 44, user_id: user2.id, round_id: round2.id)

      conn2 = Phoenix.ConnTest.build_conn() |> log_in_user(user2)
      {:ok, _view2, _html2} = live(conn2, Routes.game_room_path(conn2, :show, session.id))
      {:ok, view, html} = live(conn1, Routes.game_room_path(conn1, :show, session.id))

      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve3)

      render_click(view, "change-penalty", %{"penalty" => "+2"})
      updated_solve2 = Sessions.get_solve!(solve2.id)
      html = render(view)

      assert updated_solve2.penalty == :"+2"
      assert html =~ Sessions.display_solve(updated_solve2)
      refute html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve3)
    end

    test "change-penalty +2 does nothing if the user has no solve for the current round", %{
      conn: conn,
      user: user,
      session: session,
      round: round1
    } do
      solve = solve_fixture(user_id: user.id, round_id: round1.id)
      _round2 = round_fixture(session: session)

      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)

      render_click(view, "change-penalty", %{"penalty" => "+2"})

      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)
    end

    test "change-penalty DNF sets a DNF penalty for the user's solve in the current round", %{
      conn: conn1,
      user: user1,
      session: session,
      round: round1
    } do
      user2 = user_fixture()
      solve1 = solve_fixture(time: 42, user_id: user1.id, round_id: round1.id)

      round2 = round_fixture(session: session)
      solve2 = solve_fixture(time: 43, user_id: user1.id, round_id: round2.id)
      solve3 = solve_fixture(time: 44, user_id: user2.id, round_id: round2.id)

      conn2 = Phoenix.ConnTest.build_conn() |> log_in_user(user2)
      {:ok, _view2, _html2} = live(conn2, Routes.game_room_path(conn2, :show, session.id))
      {:ok, view, html} = live(conn1, Routes.game_room_path(conn1, :show, session.id))

      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve3)

      render_click(view, "change-penalty", %{"penalty" => "DNF"})
      updated_solve2 = Sessions.get_solve!(solve2.id)
      html = render(view)

      assert updated_solve2.penalty == :DNF
      assert html =~ Sessions.display_solve(updated_solve2)
      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve3)
    end

    test "change-penalty DNF does nothing if the user has no solve for the current round", %{
      conn: conn,
      user: user,
      session: session,
      round: round1
    } do
      solve = solve_fixture(user_id: user.id, round_id: round1.id)
      _round2 = round_fixture(session: session)

      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)

      render_click(view, "change-penalty", %{"penalty" => "DNF"})

      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)
    end

    test "change-penalty fetches stats", %{
      conn: conn,
      user: user,
      session: session,
      round: round1
    } do
      _solve1 = solve_fixture(user_id: user.id, round_id: round1.id)
      round2 = round_fixture(session: session)
      _solve2 = solve_fixture(user_id: user.id, round_id: round2.id)
      round3 = round_fixture(session: session)
      _solve3 = solve_fixture(user_id: user.id, round_id: round3.id)
      round4 = round_fixture(session: session)
      _solve4 = solve_fixture(user_id: user.id, round_id: round4.id, penalty: :DNF)
      round5 = round_fixture(session: session)
      _solve5 = solve_fixture(user_id: user.id, round_id: round5.id)

      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      refute_html(html, ".t_ao5", text: "DNF")

      html = view |> render_click("change-penalty", %{"penalty" => "DNF"})

      assert_html(html, ".t_ao5", text: "DNF")
    end

    test "send-message creates and sends messages", %{conn: conn, user: user, session: session} do
      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_messages_before = Enum.count(Messaging.list_room_messages(session))

      html
      |> assert_html("#chat")
      |> assert_html("#room-messages")
      |> refute_html(".t_room-message")
      |> assert_html("#chat-input")

      render_click(view, "send-message", %{"message" => "hello world"})
      num_messages_after = Enum.count(Messaging.list_room_messages(session))

      render(view)
      |> assert_html(".t_room-message", count: 1, text: "#{user.username}: hello world")

      assert num_messages_after == num_messages_before + 1

      render_click(view, "send-message", %{"message" => "second message"})

      render(view)
      |> assert_html(".t_room-message", count: 2)
      |> assert_html(".t_room-message:nth-child(2)", text: "#{user.username}: second message")
    end

    test "pagination flow", %{conn: conn1, user: user1, session: session} do
      user2 = user_fixture()
      conn2 = Phoenix.ConnTest.build_conn() |> log_in_user(user2)
      live(conn2, Routes.game_room_path(conn2, :show, session.id))

      user3 = user_fixture()
      conn3 = Phoenix.ConnTest.build_conn() |> log_in_user(user3)
      live(conn3, Routes.game_room_path(conn3, :show, session.id))

      user4 = user_fixture()
      conn4 = Phoenix.ConnTest.build_conn() |> log_in_user(user4)
      live(conn4, Routes.game_room_path(conn4, :show, session.id))

      user5 = user_fixture()
      conn5 = Phoenix.ConnTest.build_conn() |> log_in_user(user5)
      # Don't join with conn5 yet

      {:ok, lv, html} = live(conn1, Routes.game_room_path(conn1, :show, session.id))

      assert html =~ "4 participants"
      refute html =~ "Page"
      refute html =~ "fa-chevron-left"
      refute html =~ "fa-chevron-right"

      # Now join with conn5
      {:ok, lv5, _html5} = live(conn5, Routes.game_room_path(conn5, :show, session.id))
      html = render(lv)

      assert html =~ "5 participants"
      assert html =~ "Page 1/2"
      refute html =~ "fa-chevron-left"
      assert html =~ "fa-chevron-right"
      refute html =~ user5.username
      Enum.each([user1, user2, user3, user4], fn user -> assert html =~ user.username end)

      html = lv |> render_click("users-page-right")

      assert html =~ "Page 2/2"
      assert html =~ "fa-chevron-left"
      refute html =~ "fa-chevron-right"
      assert html =~ user5.username
      Enum.each([user1, user2, user3, user4], fn user -> refute html =~ user.username end)

      html = lv |> render_click("users-page-left")

      assert html =~ "Page 1/2"
      refute html =~ "fa-chevron-left"
      assert html =~ "fa-chevron-right"
      refute html =~ user5.username
      Enum.each([user1, user2, user3, user4], fn user -> assert html =~ user.username end)

      html = lv |> render_click("users-page-right")

      assert html =~ "Page 2/2"

      # Leave with conn5
      other_session = session_fixture()
      _other_session_round = round_fixture(session: other_session)
      live_redirect(lv5, to: "/#{other_session.id}")
      html = render(lv)

      assert html =~ "4 participants"
      refute html =~ "Page"
      refute html =~ "fa-chevron-left"
      refute html =~ "fa-chevron-right"
      Enum.each([user1, user2, user3, user4], fn user -> assert html =~ user.username end)
    end

    test "double chevron", %{conn: conn, session: session} do
      Enum.each(2..9, fn _ ->
        user_n = user_fixture()
        conn_n = Phoenix.ConnTest.build_conn() |> log_in_user(user_n)
        live(conn_n, Routes.game_room_path(conn_n, :show, session.id))
      end)

      {:ok, lv, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      assert html =~ "9 participants"
      assert html =~ "Page 1/3"
      refute html =~ "fa-chevron-left"
      assert html =~ "fa-chevron-right"

      html = lv |> render_click("users-page-right")

      assert html =~ "9 participants"
      assert html =~ "Page 2/3"
      assert html =~ "fa-chevron-left"
      assert html =~ "fa-chevron-right"

      html = lv |> render_click("users-page-right")

      assert html =~ "9 participants"
      assert html =~ "Page 3/3"
      assert html =~ "fa-chevron-left"
      refute html =~ "fa-chevron-right"
    end
  end

  describe "Sessions events" do
    setup [:authenticate]

    test "reacts to round created", %{conn: conn, session: session} do
      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_rounds_before = Enum.count(Sessions.list_rounds_of_session(session))

      assert_html(html, "tr.t_round-row", count: num_rounds_before)

      {:ok, round} = Sessions.create_round(session)

      num_rounds_after = Enum.count(Sessions.list_rounds_of_session(session))

      assert num_rounds_after == num_rounds_before + 1

      render(view)
      |> assert_html("tr.t_round-row", count: num_rounds_after)
      |> assert_html(".t_scramble", text: "&nbsp" <> round.scramble)
    end

    test "reacts to solve created", %{conn: conn, session: session, user: user} do
      {:ok, view, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_solves_before = Enum.count(Sessions.list_solves_of_session(session))

      {:ok, solve} = Sessions.create_solve(session, user, 42, :OK)

      num_solves_after = Enum.count(Sessions.list_solves_of_session(session))

      assert num_solves_after == num_solves_before + 1
      assert render(view) =~ Sessions.display_solve(solve)
    end

    test "reacts to room message created", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      room_message = room_message_fixture(session: session)

      render(view)
      |> assert_html(".t_room-message",
        count: 1,
        text: Messaging.display_room_message(room_message)
      )
    end
  end

  describe "Presence events" do
    setup [:authenticate]

    test "on join, show times and update presence display", %{
      conn: conn,
      session: session,
      round: round
    } do
      other_user = user_fixture()
      other_conn = Phoenix.ConnTest.build_conn() |> log_in_user(other_user)

      solve =
        solve_fixture(%{
          round_id: round.id,
          user_id: other_user.id,
          time: 43,
          penalty: :OK
        })

      {:ok, lv, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      assert html =~ "1 participant"
      refute html =~ other_user.username

      live(other_conn, Routes.game_room_path(other_conn, :show, session.id))

      html = render(lv)
      assert html =~ "2 participants"
      assert html =~ other_user.username
      assert html =~ Sessions.display_solve(solve)
    end

    test "on leave, hide times and update presene display", %{
      conn: conn,
      session: session,
      round: round
    } do
      other_user = user_fixture()
      other_conn = Phoenix.ConnTest.build_conn() |> log_in_user(other_user)

      solve =
        solve_fixture(%{
          round_id: round.id,
          user_id: other_user.id,
          time: 43,
          penalty: :OK
        })

      {:ok, other_lv, _other_html} =
        live(other_conn, Routes.game_room_path(other_conn, :show, session.id))

      {:ok, lv, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      assert html =~ "2 participants"
      assert html =~ other_user.username
      assert html =~ Sessions.display_solve(solve)

      other_session = session_fixture()
      _other_session_round = round_fixture(session: other_session)
      live_redirect(other_lv, to: "/#{other_session.id}")

      html = render(lv)
      assert html =~ "1 participant"
      refute html =~ other_user.username
    end
  end
end
