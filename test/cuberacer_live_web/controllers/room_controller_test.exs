defmodule CuberacerLiveWeb.RoomControllerTest do
  use CuberacerLiveWeb.ConnCase

  import CuberacerLive.AccountsFixtures
  import CuberacerLive.SessionsFixtures

  setup do
    session = session_fixture()
    %{session: session}
  end

  describe "GET /room/:id" do
    test "renders React render node", %{conn: conn, session: session} do
      conn = conn |> log_in_user(user_fixture()) |> get(Routes.room_path(conn, :show, session.id))
      assert html = html_response(conn, 200)

      assert_html(html, "div#room-root.h-full")
    end

    test "redirects if not logged in", %{conn: conn, session: session} do
      conn = conn |> get(Routes.room_path(conn, :show, session.id))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end
end
