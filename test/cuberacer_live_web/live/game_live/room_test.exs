defmodule CuberacerLiveWeb.GameLive.RoomTest do
  use CuberacerLiveWeb.ConnCase
  @moduletag ensure_presence_shutdown: true

  import Phoenix.LiveViewTest
  import Ecto.Query
  import CuberacerLive.AccountsFixtures
  import CuberacerLive.SessionsFixtures
  import CuberacerLive.CubingFixtures
  import CuberacerLive.MessagingFixtures

  alias CuberacerLive.Repo
  alias CuberacerLive.RoomCache
  alias CuberacerLive.{Sessions, Messaging}
  alias CuberacerLive.Sessions.Solve

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end

  defp create_room(_) do
    cube_type = cube_type_fixture()

    {:ok, pid, session} =
      RoomCache.create_room(%{name: "some session", cube_type_id: cube_type.id})

    # TODO: Some kind of room creation helper for tests

    on_exit(fn -> GenServer.stop(pid) end)

    # TODO: Each session should have a first round by default, so this doesn't have to happen.
    round = round_fixture(%{session_id: session.id})

    %{session: session, round: round}
  end

  defp create_penalty(_) do
    penalty = penalty_fixture(name: "OK")
    %{penalty: penalty}
  end

  defp authenticate(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end

  setup [:create_user, :create_room, :create_penalty]

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
      solve = solve_fixture(%{user_id: user.id, round_id: round.id}) |> Repo.preload([:penalty])

      assert {:ok, _view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))
      assert html =~ user.email
      assert html =~ Sessions.display_solve(solve)
    end

    test "does not display solves for user not in room", %{
      conn: conn,
      session: session,
      round: round,
      user: user
    } do
      conn = log_in_user(conn, user)
      other_user = user_fixture()

      _solve =
        solve_fixture(%{user_id: other_user.id, round_id: round.id})
        |> Repo.preload([:penalty])

      assert {:ok, _view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))
      assert html =~ user.email
      refute html =~ other_user.email
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
  end

  describe "LiveView events" do
    setup [:authenticate]

    test "new-round creates a new round", %{conn: conn, session: session} do
      Sessions.subscribe(session.id)
      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_rounds_before = Enum.count(Sessions.list_rounds_of_session(session))

      assert_html(html, "tr.t_round-row", count: num_rounds_before)

      view
      |> render_click("new-round")

      assert_receive {Sessions, [:round, :created], _round}

      num_rounds_after = Enum.count(Sessions.list_rounds_of_session(session))

      assert num_rounds_after == num_rounds_before + 1
      assert_html(render(view), "tr.t_round-row", count: num_rounds_after)
    end

    test "new-solve creates a new solve", %{conn: conn, session: session} do
      Sessions.subscribe(session.id)
      {:ok, view, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_solves_before = Enum.count(Sessions.list_solves_of_session(session))

      view
      |> render_click("new-solve", time: 42)

      assert_receive {Sessions, [:solve, :created], _solve}

      num_solves_after = Enum.count(Sessions.list_solves_of_session(session))

      newest_solve_query =
        from s in Solve,
          join: r in assoc(s, :round),
          where: r.session_id == ^session.id,
          order_by: [desc: s.inserted_at],
          limit: 1

      newest_solve = Repo.one(newest_solve_query) |> Repo.preload(:penalty)

      assert num_solves_after == num_solves_before + 1
      assert newest_solve.time == 42
      assert render(view) =~ Sessions.display_solve(newest_solve)
    end

    test "penalty-ok sets an OK penalty for the user's solve in the current round", %{
      conn: conn1,
      user: user1,
      session: session,
      round: round1
    } do
      plus2_penalty = penalty_fixture(name: "+2")
      user2 = user_fixture()
      solve1 = solve_fixture(time: 42, user_id: user1.id, round_id: round1.id)
      round2 = round_fixture(session_id: session.id)

      solve2 =
        solve_fixture(
          time: 43,
          penalty_id: plus2_penalty.id,
          user_id: user1.id,
          round_id: round2.id
        )

      solve3 = solve_fixture(time: 44, user_id: user2.id, round_id: round2.id)
      Sessions.subscribe(session.id)

      conn2 = Phoenix.ConnTest.build_conn() |> log_in_user(user2)
      {:ok, _view2, _html2} = live(conn2, Routes.game_room_path(conn2, :show, session.id))
      {:ok, view, html} = live(conn1, Routes.game_room_path(conn1, :show, session.id))

      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve3)

      render_click(view, "penalty-ok")

      assert_receive {Sessions, [:solve, :updated], _solve}

      updated_solve2 = Sessions.get_solve!(solve2.id) |> Repo.preload(:penalty)
      html = render(view)

      assert updated_solve2.penalty.name == "OK"
      assert html =~ Sessions.display_solve(updated_solve2)
      refute html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve3)
    end

    test "penalty-ok does nothing if the user has no solve for the current round", %{
      conn: conn,
      user: user,
      session: session,
      round: round1
    } do
      plus2_penalty = penalty_fixture(name: "+2")
      solve = solve_fixture(penalty_id: plus2_penalty.id, user_id: user.id, round_id: round1.id)
      _round2 = round_fixture(session_id: session.id)
      Sessions.subscribe(session.id)

      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)

      render_click(view, "penalty-ok")

      refute_receive {Sessions, _event, _result}
      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)
    end

    test "penalty-plus2 sets a +2 penalty for the user's solve in the current round", %{
      conn: conn1,
      user: user1,
      session: session,
      round: round1
    } do
      penalty_fixture(name: "+2")
      user2 = user_fixture()
      solve1 = solve_fixture(time: 42, user_id: user1.id, round_id: round1.id)

      round2 = round_fixture(session_id: session.id)
      solve2 = solve_fixture(time: 43, user_id: user1.id, round_id: round2.id)
      solve3 = solve_fixture(time: 44, user_id: user2.id, round_id: round2.id)
      Sessions.subscribe(session.id)

      conn2 = Phoenix.ConnTest.build_conn() |> log_in_user(user2)
      {:ok, _view2, _html2} = live(conn2, Routes.game_room_path(conn2, :show, session.id))
      {:ok, view, html} = live(conn1, Routes.game_room_path(conn1, :show, session.id))

      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve3)

      render_click(view, "penalty-plus2")

      assert_receive {Sessions, [:solve, :updated], _solve}

      updated_solve2 = Sessions.get_solve!(solve2.id) |> Repo.preload(:penalty)
      html = render(view)

      assert updated_solve2.penalty.name == "+2"
      assert html =~ Sessions.display_solve(updated_solve2)
      refute html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve3)
    end

    test "penalty-plus2 does nothing if the user has no solve for the current round", %{
      conn: conn,
      user: user,
      session: session,
      round: round1
    } do
      penalty_fixture(name: "+2")
      solve = solve_fixture(user_id: user.id, round_id: round1.id)
      _round2 = round_fixture(session_id: session.id)
      Sessions.subscribe(session.id)

      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)

      render_click(view, "penalty-plus2")

      refute_receive {Sessions, _event, _result}
      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)
    end

    test "penalty-dnf sets a DNF penalty for the user's solve in the current round", %{
      conn: conn1,
      user: user1,
      session: session,
      round: round1
    } do
      penalty_fixture(name: "DNF")
      user2 = user_fixture()
      solve1 = solve_fixture(time: 42, user_id: user1.id, round_id: round1.id)
      Sessions.subscribe(session.id)

      round2 = round_fixture(session_id: session.id)
      solve2 = solve_fixture(time: 43, user_id: user1.id, round_id: round2.id)
      solve3 = solve_fixture(time: 44, user_id: user2.id, round_id: round2.id)

      conn2 = Phoenix.ConnTest.build_conn() |> log_in_user(user2)
      {:ok, _view2, _html2} = live(conn2, Routes.game_room_path(conn2, :show, session.id))
      {:ok, view, html} = live(conn1, Routes.game_room_path(conn1, :show, session.id))

      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve3)

      render_click(view, "penalty-dnf")

      assert_receive {Sessions, [:solve, :updated], _solve}

      updated_solve2 = Sessions.get_solve!(solve2.id) |> Repo.preload(:penalty)
      html = render(view)

      assert updated_solve2.penalty.name == "DNF"
      assert html =~ Sessions.display_solve(updated_solve2)
      refute html =~ Sessions.display_solve(solve2)
      assert html =~ Sessions.display_solve(solve1)
      assert html =~ Sessions.display_solve(solve3)
    end

    test "penalty-dnf does nothing if the user has no solve for the current round", %{
      conn: conn,
      user: user,
      session: session,
      round: round1
    } do
      penalty_fixture(name: "DNF")
      solve = solve_fixture(user_id: user.id, round_id: round1.id)
      _round2 = round_fixture(session_id: session.id)
      Sessions.subscribe(session.id)

      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)

      render_click(view, "penalty-dnf")

      refute_receive {Sessions, _event, _result}
      assert html =~ Sessions.display_solve(solve)
      assert html =~ Sessions.display_solve(nil)
    end

    test "send-message creates and sends a message", %{conn: conn, user: user, session: session} do
      Messaging.subscribe(session.id)
      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))
      num_messages_before = Enum.count(Messaging.list_room_messages(session))

      html
      |> assert_html("#chat")
      |> assert_html("#room-messages")
      |> refute_html(".t_room-message")
      |> assert_html("#chat-input")

      render_click(view, "send-message", %{"message" => "hello world"})

      assert_receive {Messaging, [:room_message, :created], _room_message}

      num_messages_after = Enum.count(Messaging.list_room_messages(session))

      render(view)
      |> assert_html(".t_room-message", count: 1, text: "#{user.email}: hello world")

      assert num_messages_after == num_messages_before + 1
    end
  end

  describe "Sessions events" do
    setup [:authenticate]

    test "reacts to round created", %{conn: conn, session: session} do
      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_rounds_before = Enum.count(Sessions.list_rounds_of_session(session))

      assert_html(html, "tr.t_round-row", count: num_rounds_before)

      Sessions.create_round(%{session_id: session.id, scramble: "some scramble"})

      num_rounds_after = Enum.count(Sessions.list_rounds_of_session(session))

      assert num_rounds_after == num_rounds_before + 1
      assert_html(render(view), "tr.t_round-row", count: num_rounds_after)
    end

    test "reacts to solve created", %{conn: conn, session: session, user: user, penalty: penalty} do
      {:ok, view, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_solves_before = Enum.count(Sessions.list_solves_of_session(session))

      {:ok, solve} = Sessions.create_solve(session, user, 42, penalty)

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

    test "shows times for user on join", %{
      conn: conn,
      session: session,
      round: round,
      penalty: penalty
    } do
      other_user = user_fixture()
      other_conn = Phoenix.ConnTest.build_conn() |> log_in_user(other_user)

      solve =
        solve_fixture(%{
          round_id: round.id,
          user_id: other_user.id,
          time: 43,
          penalty_id: penalty.id
        })

      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      refute html =~ other_user.email

      live(other_conn, Routes.game_room_path(other_conn, :show, session.id))

      html = render(view)
      assert html =~ other_user.email
      assert html =~ Sessions.display_solve(solve)
    end

    test "hides times for user on leave", %{
      conn: conn,
      session: session,
      round: round,
      penalty: penalty
    } do
      other_user = user_fixture()
      other_conn = Phoenix.ConnTest.build_conn() |> log_in_user(other_user)

      solve =
        solve_fixture(%{
          round_id: round.id,
          user_id: other_user.id,
          time: 43,
          penalty_id: penalty.id
        })

      {:ok, other_view, _other_html} =
        live(other_conn, Routes.game_room_path(other_conn, :show, session.id))

      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      assert html =~ other_user.email
      assert html =~ Sessions.display_solve(solve)

      other_session = session_fixture()
      live_redirect(other_view, to: "/#{other_session.id}")

      refute render(view) =~ other_user.email
    end
  end
end
