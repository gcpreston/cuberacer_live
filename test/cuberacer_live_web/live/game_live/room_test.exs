defmodule CuberacerLiveWeb.GameLive.RoomTest do
  use CuberacerLiveWeb.ConnCase
  @moduletag ensure_presence_shutdown: true

  import Phoenix.LiveViewTest
  import Ecto.Query
  import CuberacerLive.AccountsFixtures
  import CuberacerLive.SessionsFixtures
  import CuberacerLive.MessagingFixtures

  alias CuberacerLive.{Repo, RoomCache, Sessions, Messaging}
  alias CuberacerLive.Sessions.Solve

  ## Helpers

  defp new_round_debounce_ms do
    Application.get_env(:cuberacer_live, :new_round_debounce_ms)
  end

  defp empty_room_timeout_ms do
    Application.get_env(:cuberacer_live, :empty_room_timeout_ms)
  end

  ## Setup functions

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end

  defp create_room(_) do
    {:ok, pid, session} = RoomCache.create_room("test room", :"3x3")

    %{session: session, pid: pid}
  end

  defp authenticate(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end

  ## Tests

  setup [:create_user, :create_room]

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

    test "redirects if inactive session", %{conn: conn, user: user, session: session, pid: pid} do
      GenServer.stop(pid)
      conn = log_in_user(conn, user)
      lobby_path = Routes.game_lobby_path(conn, :index)

      {:error, {:live_redirect, %{flash: %{"error" => "Room has terminated"}, to: ^lobby_path}}} =
        live(conn, Routes.game_room_path(conn, :show, session.id))
    end

    test "redirects if invalid room ID", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      lobby_path = Routes.game_lobby_path(conn, :index)

      {:error, {:live_redirect, %{flash: %{"error" => "Unknown room"}, to: ^lobby_path}}} =
        live(conn, Routes.game_room_path(conn, :show, "abc"))
    end

    test "redirects if unlisted and connecting with session ID", %{
      conn: conn,
      user: user
    } do
      {:ok, _pid, session} = RoomCache.create_room("unlisted room", :"3x3", true)
      conn = log_in_user(conn, user)
      lobby_path = Routes.game_lobby_path(conn, :index)

      {:error, {:live_redirect, %{flash: %{"error" => "Unknown room"}, to: ^lobby_path}}} =
        live(conn, Routes.game_room_path(conn, :show, session.id))
    end

    test "connects with valid user token", %{conn: conn, user: user, session: session} do
      conn = log_in_user(conn, user)

      assert {:ok, _lv, html} = live(conn, Routes.game_room_path(conn, :show, session.id))
      assert html =~ session.name
    end

    test "connects with valid hashed room ID", %{conn: conn, user: user, session: session} do
      conn = log_in_user(conn, user)
      s = Hashids.new(Application.fetch_env!(:cuberacer_live, :hashids_config))

      assert {:ok, _lv, html} =
               live(conn, Routes.game_room_path(conn, :show, Hashids.encode(s, session.id)))

      assert html =~ session.name
    end
  end

  describe "interface" do
    setup [:authenticate]

    test "displays solves for user in room", %{conn: conn, session: session, user: user} do
      round = Sessions.get_current_round!(session)
      solve = solve_fixture(%{user_id: user.id, round_id: round.id})

      assert {:ok, lv, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      render(lv)
      |> assert_html("th a", text: user.username)
      |> assert_html("#t_cell-round-#{round.id}-user-#{user.id}",
        text: Sessions.display_solve(solve)
      )
    end

    test "does not display solves for user not in room", %{
      conn: conn,
      session: session,
      user: user
    } do
      other_user = user_fixture()
      round = Sessions.get_current_round!(session)

      _solve = solve_fixture(%{user_id: other_user.id, round_id: round.id})

      assert {:ok, _lv, html} = live(conn, Routes.game_room_path(conn, :show, session.id))
      assert html =~ user.username
      refute html =~ other_user.username
    end

    # TODO: Write test(s) for 2 connections from same user to one room

    test "displays messages in appropriate room", %{conn: conn, session: session1, user: user} do
      other_user = user_fixture()
      session2 = session_fixture()
      message1 = room_message_fixture(session: session1, user: user, message: "some text")

      message2 =
        room_message_fixture(session: session1, user: other_user, message: "some other text")

      message3 = room_message_fixture(session: session2, user: user, message: "some third text")

      assert {:ok, _lv, html} = live(conn, Routes.game_room_path(conn, :show, session1.id))

      html
      |> assert_html(".t_room-message", count: 2)

      assert html =~ message1.message
      assert html =~ message2.message
      refute html =~ message3.message
    end

    test "displays ao5 and ao12", %{conn: conn, session: session} do
      assert {:ok, _lv, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      html
      |> assert_html(".t_ao5", count: 1, text: "DNF")
      |> assert_html(".t_ao12", count: 1, text: "DNF")
    end

    test "does not display time if user has a time for current round", %{
      conn: conn,
      session: session
    } do
      {:ok, lv, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      html
      |> assert_html(".text-gray-900 .t_scramble", count: 1)

      lv |> render_hook("timer-submit", time: 16_731)

      render(lv)
      |> assert_html(".text-gray-300 .t_scramble", count: 1)
    end

    test "displays timer toggle", %{conn: conn, session: session} do
      {:ok, lv, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      html
      |> assert_html("#timer", count: 1)
      |> refute_html("#keyboard-input")
      |> refute_html("i.fa-stopwatch")
      |> assert_html("i.fa-keyboard", count: 1)

      html = lv |> element("button[phx-click='toggle-timer']") |> render_click()

      html
      |> refute_html("#timer")
      |> assert_html("#keyboard-input", count: 1)
      |> assert_html("i.fa-stopwatch", count: 1)
      |> refute_html("i.fa-keyboard")
    end

    test "displays keyboard indicator for keyboard users", %{conn: conn1, session: session} do
      user2 = user_fixture()
      conn2 = Phoenix.ConnTest.build_conn() |> log_in_user(user2)
      {:ok, lv2, _html2} = live(conn2, Routes.game_room_path(conn2, :show, session.id))

      render_click(lv2, "toggle-timer")

      {:ok, lv1, _html1} = live(conn1, Routes.game_room_path(conn1, :show, session.id))

      assert lv1
             |> element("#header-cell-user-#{user2.id}")
             |> render() =~
               ~s(<i class="fas fa-keyboard" title="This player is using keyboard entry"></i>)

      assert lv2
             |> element("#header-cell-user-#{user2.id}")
             |> render() =~
               ~s(<i class="fas fa-keyboard" title="This player is using keyboard entry"></i>)

      exit_liveview(lv1)
      {:ok, lv1, _html1} = live(conn1, Routes.game_room_path(conn1, :show, session.id))

      assert lv1
             |> element("#header-cell-user-#{user2.id}")
             |> render() =~
               ~s(<i class="fas fa-keyboard" title="This player is using keyboard entry"></i>)

      assert lv2
             |> element("#header-cell-user-#{user2.id}")
             |> render() =~
               ~s(<i class="fas fa-keyboard" title="This player is using keyboard entry"></i>)
    end

    test "displays solving indicator", %{conn: conn1, session: session} do
      round = Sessions.get_current_round!(session)
      user2 = user_fixture()
      conn2 = Phoenix.ConnTest.build_conn() |> log_in_user(user2)
      {:ok, lv2, _html2} = live(conn2, Routes.game_room_path(conn2, :show, session.id))

      render_hook(lv2, "solving")

      {:ok, lv1, _html1} = live(conn1, Routes.game_room_path(conn1, :show, session.id))

      assert lv1
             |> element("#t_cell-round-#{round.id}-user-#{user2.id}")
             |> render() =~ "Solving..."

      assert lv2
             |> element("#t_cell-round-#{round.id}-user-#{user2.id}")
             |> render() =~ "Solving..."

      exit_liveview(lv1)
      {:ok, lv1, _html1} = live(conn1, Routes.game_room_path(conn1, :show, session.id))

      assert lv1
             |> element("#t_cell-round-#{round.id}-user-#{user2.id}")
             |> render() =~ "Solving..."

      assert lv2
             |> element("#t_cell-round-#{round.id}-user-#{user2.id}")
             |> render() =~ "Solving..."
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

      :timer.sleep(new_round_debounce_ms())

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
      session: session
    } do
      round = Sessions.get_current_round!(session)
      other_user = user_fixture()
      other_conn = Phoenix.ConnTest.build_conn() |> log_in_user(other_user)

      {:ok, other_lv, _html} =
        live(other_conn, Routes.game_room_path(other_conn, :show, session.id))

      {:ok, lv, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))
      html = render(lv)

      assert_html(html, "#t_cell-round-#{round.id}-user-#{user.id}", text: "--")

      render_hook(lv, "solving")

      render(lv)
      |> assert_html("#t_cell-round-#{round.id}-user-#{user.id}", text: "Solving...")

      render(other_lv)
      |> assert_html("#t_cell-round-#{round.id}-user-#{user.id}", text: "Solving...")
    end

    test "timer-submit creates a new solve", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_solves_before = Enum.count(Sessions.list_solves_of_session(session))

      view
      |> render_hook("timer-submit", time: 42)

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

    test "timer-submit updates current stats", %{
      conn: conn,
      user: user,
      session: session
    } do
      round1 = Sessions.get_current_round!(session)

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
        |> render_hook("timer-submit", time: 9876)

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
        |> render_hook("timer-submit", time: 6789)
        |> assert_html(".t_ao5", text: Sessions.display_stat(stats.ao5))

      stats = Sessions.current_stats(session, user)
      assert stats.ao5 != :dnf
      assert stats.ao12 == :dnf

      assert_html(html, ".t_ao12", text: "DNF")

      _round12 = round_fixture(session: session)

      html =
        live
        |> render_hook("timer-submit", time: 9012)

      stats = Sessions.current_stats(session, user)
      assert stats.ao5 != :dnf
      assert stats.ao12 != :dnf

      html
      |> assert_html(".t_ao5", text: Sessions.display_stat(stats.ao5))
      |> assert_html(".t_ao12", text: Sessions.display_stat(stats.ao12))
    end

    test "keyboard-submit creates a new solve", %{
      conn: conn,
      user: user,
      session: session
    } do
      round = Sessions.get_current_round!(session)

      {:ok, lv, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_solves_before = Enum.count(Sessions.list_solves_of_session(session))

      lv
      |> element("button[phx-click='toggle-timer']")
      |> render_click()

      lv
      |> element("#keyboard-input")
      |> render_submit(%{"keyboard_input" => %{"time" => "1:5.12"}})

      num_solves_after = Enum.count(Sessions.list_solves_of_session(session))

      newest_solve_query =
        from s in Solve,
          join: r in assoc(s, :round),
          where: r.session_id == ^session.id,
          order_by: [desc: s.inserted_at],
          limit: 1

      newest_solve = Repo.one(newest_solve_query)

      assert num_solves_after == num_solves_before + 1
      assert newest_solve.time == 65_120
      assert_html(render(lv), "#t_cell-round-#{round.id}-user-#{user.id}", text: "1:05.120")
    end

    test "change-penalty OK sets an OK penalty for the user's solve in the current round", %{
      conn: conn1,
      user: user1,
      session: session
    } do
      round1 = Sessions.get_current_round!(session)
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
      {:ok, _lv2, _html2} = live(conn2, Routes.game_room_path(conn2, :show, session.id))
      {:ok, lv, _html} = live(conn1, Routes.game_room_path(conn1, :show, session.id))
      html = render(lv)

      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve3)

      render_click(lv, "change-penalty", %{"penalty" => "OK"})
      updated_solve2 = Sessions.get_solve!(solve2.id)
      html = render(lv)

      assert updated_solve2.penalty == :OK
      assert html =~ Sessions.display_solve(updated_solve2)
      refute html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve3)
    end

    test "change-penalty OK does nothing if the user has no solve for the current round", %{
      conn: conn,
      user: user,
      session: session
    } do
      round1 = Sessions.get_current_round!(session)
      solve = solve_fixture(penalty: :"+2", user_id: user.id, round_id: round1.id)
      _round2 = round_fixture(session: session)

      {:ok, lv, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      html = render(lv)
      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)

      render_click(lv, "change-penalty", %{"penalty" => "OK"})

      html = render(lv)
      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)
    end

    test "change-penalty +2 sets a +2 penalty for the user's solve in the current round", %{
      conn: conn1,
      user: user1,
      session: session
    } do
      round1 = Sessions.get_current_round!(session)
      user2 = user_fixture()
      solve1 = solve_fixture(time: 42, user_id: user1.id, round_id: round1.id)

      round2 = round_fixture(session: session)
      solve2 = solve_fixture(time: 43, user_id: user1.id, round_id: round2.id)
      solve3 = solve_fixture(time: 44, user_id: user2.id, round_id: round2.id)

      conn2 = Phoenix.ConnTest.build_conn() |> log_in_user(user2)
      {:ok, _lv2, _html2} = live(conn2, Routes.game_room_path(conn2, :show, session.id))
      {:ok, lv, _html} = live(conn1, Routes.game_room_path(conn1, :show, session.id))
      html = render(lv)

      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve3)

      render_click(lv, "change-penalty", %{"penalty" => "+2"})
      updated_solve2 = Sessions.get_solve!(solve2.id)
      html = render(lv)

      assert updated_solve2.penalty == :"+2"
      assert html =~ Sessions.display_solve(updated_solve2)
      refute html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve3)
    end

    test "change-penalty +2 does nothing if the user has no solve for the current round", %{
      conn: conn,
      user: user,
      session: session
    } do
      round1 = Sessions.get_current_round!(session)
      solve = solve_fixture(user_id: user.id, round_id: round1.id)
      _round2 = round_fixture(session: session)

      {:ok, lv, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      html = render(lv)
      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)

      render_click(lv, "change-penalty", %{"penalty" => "+2"})

      html = render(lv)
      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)
    end

    test "change-penalty DNF sets a DNF penalty for the user's solve in the current round", %{
      conn: conn1,
      user: user1,
      session: session
    } do
      round1 = Sessions.get_current_round!(session)
      user2 = user_fixture()
      solve1 = solve_fixture(time: 42, user_id: user1.id, round_id: round1.id)

      round2 = round_fixture(session: session)
      solve2 = solve_fixture(time: 43, user_id: user1.id, round_id: round2.id)
      solve3 = solve_fixture(time: 44, user_id: user2.id, round_id: round2.id)

      conn2 = Phoenix.ConnTest.build_conn() |> log_in_user(user2)
      {:ok, _lv2, _html2} = live(conn2, Routes.game_room_path(conn2, :show, session.id))
      {:ok, lv, _html} = live(conn1, Routes.game_room_path(conn1, :show, session.id))
      html = render(lv)

      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve3)

      render_click(lv, "change-penalty", %{"penalty" => "DNF"})
      updated_solve2 = Sessions.get_solve!(solve2.id)
      html = render(lv)

      assert updated_solve2.penalty == :DNF
      assert html =~ Sessions.display_solve(updated_solve2)
      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve3)
    end

    test "change-penalty DNF does nothing if the user has no solve for the current round", %{
      conn: conn,
      user: user,
      session: session
    } do
      round1 = Sessions.get_current_round!(session)
      solve = solve_fixture(user_id: user.id, round_id: round1.id)
      _round2 = round_fixture(session: session)

      {:ok, lv, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      html = render(lv)
      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)

      render_click(lv, "change-penalty", %{"penalty" => "DNF"})

      html = render(lv)
      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)
    end

    test "change-penalty fetches stats", %{conn: conn, user: user, session: session} do
      round1 = Sessions.get_current_round!(session)
      _solve1 = solve_fixture(user_id: user.id, round_id: round1.id)
      round2 = round_fixture(session: session)
      _solve2 = solve_fixture(user_id: user.id, round_id: round2.id)
      round3 = round_fixture(session: session)
      _solve3 = solve_fixture(user_id: user.id, round_id: round3.id)
      round4 = round_fixture(session: session)
      _solve4 = solve_fixture(user_id: user.id, round_id: round4.id, penalty: :DNF)
      round5 = round_fixture(session: session)
      _solve5 = solve_fixture(user_id: user.id, round_id: round5.id)

      {:ok, lv, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      refute_html(html, ".t_ao5", text: "DNF")

      html = render_click(lv, "change-penalty", %{"penalty" => "DNF"})

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

      assert view
             |> element(~s{[id^="room-message-"] span:first-child()})
             |> render() =~ user.username

      assert view
             |> element(~s{[id^="room-message-"] span:nth-child(2)})
             |> render() =~ "hello world"

      assert num_messages_after == num_messages_before + 1

      render_click(view, "send-message", %{"message" => "second message"})

      assert view
             |> element(~s{[id^="room-message-"]:nth-child(2) span:first-child()})
             |> render() =~ user.username

      assert view
             |> element(~s{[id^="room-message-"]:nth-child(2) span:nth-child(2)})
             |> render() =~ "second message"
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
      |> assert_html(".t_scramble", text: round.scramble)
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

      user = user_fixture()
      room_message = room_message_fixture(session: session, user: user)

      assert view
             |> element("#room-message-#{room_message.id} span:first-child()")
             |> render() =~ user.username

      assert view
             |> element("#room-message-#{room_message.id} span:nth-child(2)")
             |> render() =~ room_message.message
    end
  end

  describe "Presence events" do
    setup [:authenticate]

    test "on join, show times and update presence display", %{conn: conn, session: session} do
      round = Sessions.get_current_round!(session)
      other_user = user_fixture()
      other_conn = Phoenix.ConnTest.build_conn() |> log_in_user(other_user)

      solve =
        solve_fixture(%{
          round_id: round.id,
          user_id: other_user.id,
          time: 43,
          penalty: :OK
        })

      {:ok, lv, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      html = render(lv)
      assert html =~ "1 participant"
      refute html =~ other_user.username

      live(other_conn, Routes.game_room_path(other_conn, :show, session.id))

      html = render(lv)
      assert html =~ "2 participants"
      assert html =~ other_user.username
      assert html =~ Sessions.display_solve(solve)
    end

    test "on leave, hide times and update presence display", %{
      conn: conn,
      session: session
    } do
      round = Sessions.get_current_round!(session)
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

      {:ok, lv, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      html = render(lv)
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

  describe "Lifecycle" do
    setup [:authenticate]

    test "room terminates after configured period of time", %{session: session} do
      assert RoomCache.list_room_ids() == [session.id]

      :timer.sleep(empty_room_timeout_ms() + 10)

      assert RoomCache.list_room_ids() == []
    end

    test "room does not terminate if there is at least one participant", %{
      conn: conn,
      session: session
    } do
      assert RoomCache.list_room_ids() == [session.id]

      {:ok, lv, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))
      :timer.sleep(empty_room_timeout_ms())

      assert RoomCache.list_room_ids() == [session.id]

      exit_liveview(lv)

      assert RoomCache.list_room_ids() == [session.id]

      :timer.sleep(empty_room_timeout_ms() * 2)

      assert RoomCache.list_room_ids() == []
    end
  end
end
