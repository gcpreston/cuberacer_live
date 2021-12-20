defmodule CuberacerLiveWeb.GameLive.RoomTest do
  use CuberacerLiveWeb.ConnCase

  import Phoenix.LiveViewTest
  import CuberacerLive.SessionsFixtures
  import CuberacerLive.AccountsFixtures

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end

  defp create_session(_) do
    session = session_fixture()
    %{session: session}
  end

  describe "mount" do
    setup [:create_user, :create_session]

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

    @tag ensure_presence_shutdown: true
    test "connects with valid user token", %{conn: conn, session: session, user: user} do
      conn = log_in_user(conn, user)

      assert {:ok, _view, html} = live(conn, Routes.game_room_path(conn, :show, session.id))
      assert html =~ session.name
    end
  end
end
