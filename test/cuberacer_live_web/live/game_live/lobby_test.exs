defmodule CuberacerLive.GameLive.LobbyTest do
  use CuberacerLiveWeb.ConnCase
  @moduletag ensure_presence_shutdown: true

  import Phoenix.LiveViewTest
  import CuberacerLive.AccountsFixtures

  alias CuberacerLive.RoomCache

  setup :register_and_log_in_user

  describe ":index" do
    test "displays only active rooms", %{conn: conn} do
      {:ok, pid1, session1} = RoomCache.create_room("test room", :"3x3")

      {:ok, lv, html} = live(conn, ~p"/lobby")

      html
      |> assert_html(".t_room-card", count: 1)
      |> assert_html("#t_room-card-#{session1.id}", count: 1)

      assert html =~ session1.name
      assert html =~ "#{session1.puzzle_type}"

      {:ok, _pid2, session2} = RoomCache.create_room("test room 2", :"2x2")
      :timer.sleep(2)
      html = render(lv)

      html
      |> assert_html(".t_room-card", count: 2)
      |> assert_html("#t_room-card-#{session1.id}", count: 1)
      |> assert_html("#t_room-card-#{session2.id}", count: 1)

      assert html =~ session2.name
      assert html =~ "#{session2.puzzle_type}"

      GenServer.stop(pid1)
      :timer.sleep(2)

      render(lv)
      |> assert_html(".t_room-card", count: 1)
      |> assert_html("#t_room-card-#{session2.id}", count: 1)
    end

    test "patches to new room modal", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/lobby")

      live
      |> element("#t_new-room")
      |> render_click()

      assert_patch(live, ~p"/lobby/new")
    end

    test "shows correct copy when there are no rooms", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/lobby")

      refute_html(html, ".t_room-card")
      assert html =~ "Welcome"
      assert html =~ "Create a room to get things started!"
    end

    test "shows correct copy when there are rooms", %{conn: conn} do
      {:ok, _pid, _session} = RoomCache.create_room("test room", :"3x3")
      {:ok, _live, html} = live(conn, ~p"/lobby")

      assert_html(html, ".t_room-card", count: 1)
      assert html =~ "Welcome"
      assert html =~ "Join a room below, or create your own!"
    end

    test "changes copy when rooms are created or terminated", %{conn: conn} do
      {:ok, live, html} = live(conn, ~p"/lobby")

      refute_html(html, ".t_room-card")
      assert html =~ "Welcome"
      assert html =~ "Create a room to get things started!"

      {:ok, pid, _session} = RoomCache.create_room("test room", :"3x3")
      :timer.sleep(2)

      html = render(live)
      assert_html(html, ".t_room-card", count: 1)
      assert html =~ "Welcome"
      assert html =~ "Join a room below, or create your own!"

      GenServer.stop(pid)
      :timer.sleep(2)

      html = render(live)
      refute_html(html, ".t_room-card")
      assert html =~ "Welcome"
      assert html =~ "Create a room to get things started!"
    end

    test "shows number of users in lobby", %{conn: conn1} do
      user2 = user_fixture()
      conn2 = build_conn() |> log_in_user(user2)

      {:ok, lv1, html1} = live(conn1, ~p"/lobby")

      assert html1 =~ "1 user in the lobby"

      {:ok, _lv2, _html2} = live(conn2, ~p"/lobby")

      assert render(lv1) =~ "2 users in the lobby"
    end

    test "shows number of users in rooms", %{conn: conn1} do
      user2 = user_fixture()
      conn2 = build_conn() |> log_in_user(user2)

      {:ok, _pid, %CuberacerLive.Sessions.Session{id: session_id}} =
        RoomCache.create_room("test room", :"3x3")

      {:ok, lv1, html1} = live(conn1, ~p"/lobby")

      html1
      |> assert_html(".t_room-card", count: 1)
      |> assert_html(".t_room-participants", text: "0")
      |> refute_html(".bg-green-500.h-3.w-3.rounded-full")

      {:ok, lv2, _html2} = live(conn2, ~p"/rooms/#{session_id}")

      render(lv1)
      |> assert_html(".t_room-participants", text: "1")
      |> assert_html(".bg-green-500.h-3.w-3.rounded-full")

      exit_liveview(lv2)

      :timer.sleep(2)

      render(lv1)
      |> assert_html(".t_room-participants", text: "0")
      |> refute_html(".bg-green-500.h-3.w-3.rounded-full")
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, ~p"/lobby")
      assert redirected_to(conn) == ~p"/login"
    end
  end

  describe ":new" do
    test "displays create room modal correctly", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/lobby/new")

      html
      |> assert_html("h2.t_new-room-title", text: "New Room")
      |> assert_html(".t_room-name-input", count: 1)
      |> assert_html(".t_room-cube-type-input", count: 1)
      |> assert_html(".t_room-save", count: 1)

      Enum.each(Whisk.puzzle_types(), fn puzzle_type ->
        assert_html(html, "option[value='#{puzzle_type}']", count: 1)
      end)
    end

    @tag :ensure_presence_shutdown
    test "create room modal creates a new room with an initial round", %{user: user, conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/lobby/new")

      refute_html(html, ".t_room-card")

      result =
        lv
        |> form("#create-room-form")
        |> render_submit(%{session: %{name: "new session", puzzle_type: :"2x2"}})

      flash = assert_redirect(lv, ~p"/lobby")
      assert flash["info"] == "Room created successfully"

      {:ok, lv, html} = follow_redirect(result, conn)

      assert_html(html, ".t_room-card", count: 1)

      result =
        lv
        |> element(".t_room-card-button")
        |> render_click()

      assert_redirect(lv)

      {:ok, room_lv, _html} = follow_redirect(result, conn)

      render(room_lv)
      |> assert_html("#user-#{user.id}-rounds > div", count: 1)
      |> assert_html(".t_scramble")
    end

    @tag :ensure_presence_shutdown
    test "create room modal creates a new private room", %{conn: conn1} do
      user2 = user_fixture()
      conn2 = build_conn() |> log_in_user(user2)

      {:ok, lv, html} = live(conn1, ~p"/lobby/new")

      refute_html(html, ".t_room-card")

      result =
        lv
        |> form("#create-room-form")
        |> render_submit(%{
          session: %{name: "new session", puzzle_type: :"2x2", password: "hello"}
        })

      flash = assert_redirect(lv, ~p"/lobby")
      assert flash["info"] == "Room created successfully"

      # Shows up for user who created the room
      {:ok, lv1, html1} = follow_redirect(result, conn1)

      assert_html(html1, ".t_room-card", count: 1)
      assert lv1 |> element(".t_room-card") |> render() =~ "fa-lock"

      # Shows up for other user as well
      {:ok, lv2, html2} = live(conn2, ~p"/lobby")

      assert_html(html2, ".t_room-card", count: 1)
      assert lv2 |> element(".t_room-card") |> render() =~ "fa-lock"
    end

    test "only shows join room modal for unauthorized users", %{user: user1, conn: conn1} do
      user2 = user_fixture()
      conn2 = build_conn() |> log_in_user(user2)

      {:ok, lv, html} = live(conn1, ~p"/lobby/new")

      refute_html(html, ".t_room-card")

      result =
        lv
        |> form("#create-room-form")
        |> render_submit(%{
          session: %{name: "new session", puzzle_type: :"2x2", password: "hello"}
        })

      flash = assert_redirect(lv, ~p"/lobby")
      assert flash["info"] == "Room created successfully"

      # User who created room is already authorized
      {:ok, lv1, html1} = follow_redirect(result, conn1)

      assert_html(html1, ".t_room-card", count: 1)
      assert lv1 |> element(".t_room-card") |> render() =~ "fa-lock"

      result =
        lv1
        |> element(".t_room-card-button")
        |> render_click()

      assert_redirect(lv1)

      {:ok, room_lv1, _html1} = follow_redirect(result, conn1)

      render(room_lv1)
      |> assert_html("#user-#{user1.id}-rounds > div", count: 1)
      |> assert_html(".t_scramble")

      # Other user needs to enter password
      {:ok, lv2, html2} = live(conn2, ~p"/lobby")

      assert_html(html2, ".t_room-card", count: 1)
      assert lv2 |> element(".t_room-card") |> render() =~ "fa-lock"

      lv2
      |> element(".t_room-card-button")
      |> render_click()

      path = assert_patch(lv2)
      assert path =~ "/lobby/join/"

      result =
        lv2
        |> form("#join-room-form")
        |> render_submit(%{session: %{password: "hello"}})

      assert_redirect(lv2)

      {:ok, room_lv2, _html2} = follow_redirect(result, conn2)

      render(room_lv2)
      |> assert_html("#user-#{user2.id}-rounds > div", count: 1)
      |> assert_html(".t_scramble")
    end

    test "join room modal checks password", %{conn: conn1} do
      user2 = user_fixture()
      {:ok, _pid, session} = RoomCache.create_room("private room", :"3x3", "password", user2)

      {:ok, lv, html} = live(conn1, ~p"/lobby")

      assert_html(html, ".t_room-card", count: 1)
      assert lv |> element(".t_room-card") |> render() =~ "fa-lock"

      lv
      |> element(".t_room-card-button")
      |> render_click()

      path = assert_patch(lv)
      assert path =~ "/lobby/join/"

      result =
        lv
        |> form("#join-room-form")
        |> render_submit(%{session: %{password: "wrong password"}})

      refute_redirected(lv, ~p"/rooms/#{session.id}")
      assert_html(result, "span[phx-feedback-for=\"session[password]\"", text: "is not valid")

      lv
      |> form("#join-room-form")
      |> render_submit(%{session: %{password: "password"}})

      assert_redirect(lv, ~p"/rooms/#{session.id}")
    end

    test "displays error messages", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/lobby/new")

      html =
        live
        |> form("#create-room-form")
        |> render_submit(%{session: %{name: "", puzzle_type: :"3x3"}})

      refute_redirected(live, ~p"/lobby")

      assert_html(html, ~s(.invalid-feedback[phx-feedback-for="session[name]"),
        text: "can't be blank"
      )
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, ~p"/lobby/new")
      assert redirected_to(conn) == ~p"/login"
    end
  end
end
