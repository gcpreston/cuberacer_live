defmodule CuberacerLiveWeb.GameLive.RoomTest do
  use CuberacerLiveWeb.ConnCase
  @moduletag ensure_presence_shutdown: true

  import Phoenix.LiveViewTest
  import Ecto.Query
  import CuberacerLive.AccountsFixtures
  import CuberacerLive.SessionsFixtures
  import CuberacerLive.CubingFixtures

  alias CuberacerLive.Repo
  alias CuberacerLive.Sessions
  alias CuberacerLive.Sessions.Solve

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end

  defp create_session(_) do
    session = session_fixture()
    # TODO: Each session should have a first round by default, so this doesn't have to happen.
    round = round_fixture(%{session_id: session.id})

    %{session: session, round: round}
  end

  defp create_penalty(_) do
    penalty = penalty_fixture()
    %{penalty: penalty}
  end

  defp authenticate(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end

  setup [:create_user, :create_session, :create_penalty]

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
  end

  describe "LiveView events" do
    setup [:authenticate]

    test "new-round creates a new round", %{conn: conn, session: session} do
      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_rounds_before = Enum.count(Sessions.list_rounds_of_session(session))

      assert_html html, "tr.t_round-row", count: num_rounds_before

      view
      |> render_click("new-round")

      num_rounds_after = Enum.count(Sessions.list_rounds_of_session(session))

      assert num_rounds_after == num_rounds_before + 1
      assert_html render(view), "tr.t_round-row", count: num_rounds_after
    end

    test "new-solve creates a new solve", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_solves_before = Enum.count(Sessions.list_solves_of_session(session))

      view
      |> render_click("new-solve", time: 42)

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
  end

  describe "Sessions events" do
    setup [:authenticate]

    test "reacts to round created", %{conn: conn, session: session} do
      {:ok, view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_rounds_before = Enum.count(Sessions.list_rounds_of_session(session))

      assert_html html, "tr.t_round-row", count: num_rounds_before

      Sessions.create_round(%{session_id: session.id, scramble: "some scramble"})

      num_rounds_after = Enum.count(Sessions.list_rounds_of_session(session))

      assert num_rounds_after == num_rounds_before + 1
      assert_html render(view), "tr.t_round-row", count: num_rounds_after
    end

    test "reacts to solve created", %{conn: conn, session: session, user: user, penalty: penalty} do
      {:ok, view, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_solves_before = Enum.count(Sessions.list_solves_of_session(session))

      {:ok, solve} = Sessions.create_solve(session, user, 42, penalty)

      num_solves_after = Enum.count(Sessions.list_solves_of_session(session))

      assert num_solves_after == num_solves_before + 1
      assert render(view) =~ Sessions.display_solve(solve)
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

      solve = solve_fixture(%{
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

      solve = solve_fixture(%{
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
