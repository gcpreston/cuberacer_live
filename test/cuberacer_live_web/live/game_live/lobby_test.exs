defmodule CuberacerLive.GameLive.LobbyTest do
  use CuberacerLiveWeb.ConnCase

  import Phoenix.LiveViewTest
  import CuberacerLive.SessionsFixtures

  defp create_session(_) do
    session = session_fixture()
    %{session: session}
  end

  setup [:create_session]

  test "displays all sessions", %{conn: conn, session: session} do
    {:ok, _index_live, html} = live(conn, Routes.game_lobby_path(conn, :index))

    assert html =~ "Lobby"
    assert html =~ session.name
  end
end