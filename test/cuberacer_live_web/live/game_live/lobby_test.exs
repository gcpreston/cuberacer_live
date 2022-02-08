defmodule CuberacerLive.GameLive.LobbyTest do
  use CuberacerLiveWeb.ConnCase

  import Phoenix.LiveViewTest
  import CuberacerLive.SessionsFixtures
  import CuberacerLive.CubingFixtures

  alias CuberacerLive.Sessions

  setup :register_and_log_in_user

  describe ":index" do
    test "displays all sessions", %{conn: conn} do
      session = session_fixture() |> CuberacerLive.Repo.preload(:cube_type)
      {:ok, _live, html} = live(conn, Routes.game_lobby_path(conn, :index))

      html
      |> assert_html(".t_room-card", count: 1)
      |> assert_html("#t_room-card-#{session.id}", count: 1)

      assert html =~ session.name
      assert html =~ session.cube_type.name
    end

    test "patches to new room modal", %{conn: conn} do
      {:ok, live, _html} = live(conn, Routes.game_lobby_path(conn, :index))

      live
      |> element("#t_new-room")
      |> render_click()

      assert_patch(live, Routes.game_lobby_path(conn, :new))
    end

    test "shows correct copy when there are no rooms", %{conn: conn} do
      {:ok, _live, html} = live(conn, Routes.game_lobby_path(conn, :index))

      refute_html(html, ".t_room-card")
      assert html =~ "Welcome"
      assert html =~ "Create a room to get things started!"
    end

    test "shows correct copy when there are rooms", %{conn: conn} do
      _session = session_fixture()
      {:ok, _live, html} = live(conn, Routes.game_lobby_path(conn, :index))

      assert_html(html, ".t_room-card", count: 1)
      assert html =~ "Welcome"
      assert html =~ "Join a room below, or create your own!"
    end

    test "changes copy when rooms are created or terminated", %{conn: conn} do
      {:ok, live, html} = live(conn, Routes.game_lobby_path(conn, :index))

      refute_html(html, ".t_room-card")
      assert html =~ "Welcome"
      assert html =~ "Create a room to get things started!"

      session = session_fixture()

      html = render(live)
      assert_html(html, ".t_room-card", count: 1)
      assert html =~ "Welcome"
      assert html =~ "Join a room below, or create your own!"

      Sessions.delete_session(session)

      html = render(live)
      refute_html(html, ".t_room-card")
      assert html =~ "Welcome"
      assert html =~ "Create a room to get things started!"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.game_lobby_path(conn, :index))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  describe ":new" do
    test "displays create room modal correctly", %{conn: conn} do
      cube_type_1 = cube_type_fixture(name: "2x2")
      cube_type_2 = cube_type_fixture(name: "3x3")
      {:ok, _live, html} = live(conn, Routes.game_lobby_path(conn, :new))

      html
      |> assert_html("h2.t_new-room-title", text: "New Room")
      |> assert_html(".t_room-name-input", count: 1)
      |> assert_html(".t_room-cube-type-input", count: 1)
      |> assert_html("option[value=#{cube_type_1.id}", count: 1)
      |> assert_html("option[value=#{cube_type_2.id}", count: 1)
      |> assert_html(".t_room-save", count: 1)
    end

    @tag :ensure_presence_shutdown
    test "create room modal creates a new room with an initial round", %{conn: conn} do
      cube_type = cube_type_fixture()
      {:ok, live, html} = live(conn, Routes.game_lobby_path(conn, :new))

      refute_html(html, ".t_room-card")

      result =
        live
        |> form("#create-room-form")
        |> render_submit(%{session: %{name: "new session", cube_type_id: cube_type.id}})

      assert_redirect(live, Routes.game_lobby_path(conn, :index))

      {:ok, lobby_live, html} = follow_redirect(result, conn)

      assert_html(html, ".t_room-card", count: 1)

      result =
        lobby_live
        |> element(".t_room-card")
        |> render_click()

      assert_redirect(lobby_live)

      {:ok, _room_live, html} = follow_redirect(result, conn)

      html
      |> assert_html(".t_round-row", count: 1)
      |> assert_html(".t_scramble")
    end

    test "displays error messages", %{conn: conn} do
      cube_type = cube_type_fixture()
      {:ok, live, _html} = live(conn, Routes.game_lobby_path(conn, :new))

      html =
        live
        |> form("#create-room-form")
        |> render_submit(%{session: %{name: "", cube_type_id: cube_type.id}})

      refute_redirected(live, Routes.game_lobby_path(conn, :index))

      assert_html(html, ~s(.invalid-feedback[phx-feedback-for="session[name]"),
        text: "can't be blank"
      )
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.game_lobby_path(conn, :new))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end
end
