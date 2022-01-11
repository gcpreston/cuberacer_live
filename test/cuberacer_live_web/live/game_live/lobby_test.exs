defmodule CuberacerLive.GameLive.LobbyTest do
  use CuberacerLiveWeb.ConnCase

  import Phoenix.LiveViewTest
  import CuberacerLive.SessionsFixtures
  import CuberacerLive.CubingFixtures

  setup :register_and_log_in_user

  describe ":index" do
    test "displays all sessions", %{conn: conn} do
      session = session_fixture() |> CuberacerLive.Repo.preload(:cube_type)
      {:ok, _live, html} = live(conn, Routes.game_lobby_path(conn, :index))

      assert html =~ "Lobby"
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
      |> assert_html("h2", text: "New Room")
      |> assert_html(".t_room-name-input", count: 1)
      |> assert_html(".t_room-cube-type-input", count: 1)
      |> assert_html("option[value=#{cube_type_1.id}", count: 1)
      |> assert_html("option[value=#{cube_type_2.id}", count: 1)
      |> assert_html(".t_room-save", count: 1)
    end

    test "create room modal creates a new room", %{conn: conn} do
      cube_type = cube_type_fixture()
      {:ok, live, html} = live(conn, Routes.game_lobby_path(conn, :new))

      refute_html(html, ".t_room")

      result =
        live
        |> form("#create-room-form")
        |> render_submit(%{session: %{name: "new session", cube_type_id: cube_type.id}})

      assert_redirect(live, Routes.game_lobby_path(conn, :index))

      {:ok, _live, html} = follow_redirect(result, conn)

      assert_html(html, ".t_room", count: 1)
    end

    test "displays error messages", %{conn: conn} do
      cube_type = cube_type_fixture()
      {:ok, live, _html} = live(conn, Routes.game_lobby_path(conn, :new))

      html =
        live
        |> form("#create-room-form")
        |> render_submit(%{session: %{name: "", cube_type_id: cube_type.id}})

      refute_redirected(live, Routes.game_lobby_path(conn, :index))
      assert_html(html, ~s(.invalid-feedback[phx-feedback-for="session[name]"), text: "can't be blank")
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.game_lobby_path(conn, :new))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end
end
