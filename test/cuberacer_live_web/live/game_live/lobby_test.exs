defmodule CuberacerLive.GameLive.LobbyTest do
  use CuberacerLiveWeb.ConnCase

  import Phoenix.LiveViewTest
  import CuberacerLive.CubingFixtures
  import CuberacerLive.AccountsFixtures
  import CuberacerLive.SessionsFixtures

  alias CuberacerLive.{RoomCache, RoomServer}
  alias CuberacerLive.Sessions

  defp create_cube_type(_) do
    cube_type = cube_type_fixture()
    %{cube_type: cube_type}
  end

  defp create_room(%{cube_type: cube_type}) do
    {:ok, pid, session} =
      RoomCache.create_room(%{name: "test session", cube_type_id: cube_type.id})

    on_exit(fn -> GenServer.stop(pid) end)

    %{room_pid: pid, session: session}
  end

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end

  defp authenticate(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end

  setup [:create_cube_type, :create_room]

  test "only displays active sessions", %{conn: conn, session: session, cube_type: cube_type} do
    {:ok, other_session} =
      Sessions.create_session(%{name: "other session", cube_type_id: cube_type.id})

    {:ok, _index_live, html} = live(conn, Routes.game_lobby_path(conn, :index))

    html
    |> assert_html(".t_room", count: 1)
    |> assert_html(".t_session-name", count: 1, text: session.name)
    |> assert_html(".t_cube-type", count: 1, text: session.cube_type.name)
    |> assert_html(".t_participant-count", count: 1, text: "0")

    refute html =~ other_session.name
  end

  test "adds new rooms to view", %{conn: conn, cube_type: cube_type} do
    {:ok, view, html} = live(conn, Routes.game_lobby_path(conn, :index))
    RoomServer.subscribe()

    html
    |> assert_html(".t_room", count: 1)

    {:ok, _pid, other_session} =
      RoomCache.create_room(%{name: "other session", cube_type_id: cube_type.id})

    assert_receive {RoomServer, :room_created, ^other_session}

    render(view)
    |> assert_html(".t_room", count: 2)
  end

  test "removes inactive rooms from view", %{conn: conn, room_pid: pid, session: session} do
    {:ok, view, html} = live(conn, Routes.game_lobby_path(conn, :index))
    RoomServer.subscribe()

    html
    |> assert_html(".t_room", count: 1)

    GenServer.stop(pid)

    assert_receive {RoomServer, :room_terminated, ^session}

    IO.inspect(RoomCache.list_active_rooms(), label: "active rooms from test")
    :timer.sleep(100)
    IO.inspect(RoomCache.list_active_rooms(), label: "active rooms from test 2")

    render(view)
    |> refute_html(".t_room")
  end

  describe "Presence events" do
    setup [:create_user, :authenticate]

    test "participant count changes on room join", %{conn: other_conn, session: session} do
      conn = Phoenix.ConnTest.build_conn()
      {:ok, lobby_view, lobby_html} = live(conn, Routes.game_lobby_path(conn, :index))
      RoomCache.subscribe()

      lobby_html
      |> assert_html(".t_participant-count", text: "0")

      {:ok, _room_view, _room_html} =
        live(other_conn, Routes.game_room_path(other_conn, :show, session.id))

      assert_receive {RoomCache, :set_participant_count, _}

      render(lobby_view)
      |> assert_html(".t_participant-count", text: "1")
    end

    test "participant count changes on room leave", %{conn: other_conn, session: session} do
      conn = Phoenix.ConnTest.build_conn()
      other_session = session_fixture()

      {:ok, room_view, _room_html} =
        live(other_conn, Routes.game_room_path(other_conn, :show, session.id))

      {:ok, lobby_view, lobby_html} = live(conn, Routes.game_lobby_path(conn, :index))
      RoomCache.subscribe()

      lobby_html
      |> assert_html(".t_participant-count", text: "1")

      live_redirect(room_view, to: "/#{other_session.id}")

      assert_receive {RoomCache, :set_participant_count, _}

      render(lobby_view)
      |> assert_html(".t_participant-count", text: "0")
    end
  end
end
