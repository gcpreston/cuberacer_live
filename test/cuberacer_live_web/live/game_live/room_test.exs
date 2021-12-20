defmodule CuberacerLiveWeb.GameLive.RoomTest do
  use CuberacerLiveWeb.ConnCase
  @moduletag ensure_presence_shutdown: true

  import Phoenix.LiveViewTest
  import Ecto.Query
  import CuberacerLive.AccountsFixtures
  import CuberacerLive.SessionsFixtures
  import CuberacerLive.CubingFixtures

  alias CuberacerLive.Sessions
  alias CuberacerLive.Sessions.Solve

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end

  defp create_session(_) do
    session = session_fixture()
    %{session: session}
  end

  defp create_penalty(_) do
    penalty = penalty_fixture()
    %{penalty: penalty}
  end

  defp authenticate(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end

  setup [:create_user, :create_session]

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
  end

  describe "click events" do
    setup [:authenticate, :create_penalty]

    test "new-round creates a new round", %{conn: conn, session: session} do
      {:ok, view, _html} = live(conn, Routes.game_room_path(conn, :show, session.id))

      num_rounds_before = Enum.count(Sessions.list_rounds_of_session(session))

      view
      |> render_click("new-round")

      num_rounds_after = Enum.count(Sessions.list_rounds_of_session(session))
      newest_round = Sessions.get_current_round(session)

      assert num_rounds_after == num_rounds_before + 1
      assert render(view) =~ newest_round.scramble
    end

    test "new-solve creates a new solve", %{conn: conn, session: session} do
      # TODO: Each session should have a first round by default, so this doesn't have to happen.
      Sessions.create_round(%{session_id: session.id})
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

      newest_solve = CuberacerLive.Repo.one(newest_solve_query)

      assert num_solves_after == num_solves_before + 1
      assert newest_solve.time == 42
      assert render(view) =~ Integer.to_string(newest_solve.time)
    end
  end
end
