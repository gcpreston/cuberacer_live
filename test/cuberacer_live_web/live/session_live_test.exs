defmodule CuberacerLiveWeb.SessionLiveTest do
  use CuberacerLiveWeb.ConnCase

  import Phoenix.LiveViewTest
  import CuberacerLive.SessionsFixtures

  alias CuberacerLive.Sessions

  @create_attrs %{name: "some other name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_session(_) do
    session = session_fixture()
    %{session: session}
  end

  describe "Index" do
    setup [:create_session]

    test "lists all sessions", %{conn: conn, session: session} do
      {:ok, _index_live, html} = live(conn, Routes.session_index_path(conn, :index))

      assert html =~ "Listing Sessions"
      assert html =~ session.name
    end

    test "saves new session", %{conn: conn} do
      {:ok, index_live, html} = live(conn, Routes.session_index_path(conn, :index))

      refute html =~ "some other name"

      assert index_live |> element("a", "New Session") |> render_click() =~
               "New Session"

      assert_patch(index_live, Routes.session_index_path(conn, :new))

      assert index_live
             |> form("#session-form", session: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#session-form", session: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.session_index_path(conn, :index))

      assert html =~ "Session created successfully"
      assert html =~ "some other name"
    end

    test "updates session in listing", %{conn: conn, session: session} do
      {:ok, index_live, _html} = live(conn, Routes.session_index_path(conn, :index))

      assert index_live |> element("#session-#{session.id} a", "Edit") |> render_click() =~
               "Edit Session"

      assert_patch(index_live, Routes.session_index_path(conn, :edit, session))

      assert index_live
             |> form("#session-form", session: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#session-form", session: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.session_index_path(conn, :index))

      assert html =~ "Session updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes session in listing", %{conn: conn, session: session} do
      {:ok, index_live, _html} = live(conn, Routes.session_index_path(conn, :index))

      assert index_live |> element("#session-#{session.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#session-#{session.id}")
    end

    test "dsplays new session created elsewhere", %{conn: conn} do
      {:ok, index_live, html} = live(conn, Routes.session_index_path(conn, :index))

      refute html =~ "some other name"

      {:ok, _session} = Sessions.create_session(@create_attrs)

      assert render(index_live) =~ "some other name"
    end

    test "displays session updated from elsewhere", %{conn: conn, session: session} do
      {:ok, index_live, html} = live(conn, Routes.session_index_path(conn, :index))

      refute html =~ "some updated name"

      {:ok, _session} = Sessions.update_session(session, @update_attrs)

      assert render(index_live) =~ "some updated name"
    end

    test "removes session deleted from elsewhere", %{conn: conn, session: session} do
      {:ok, index_live, html} = live(conn, Routes.session_index_path(conn, :index))

      assert html =~ session.name

      {:ok, _session} = Sessions.delete_session(session)

      refute render(index_live) =~ session.name
    end
  end

  describe "Show" do
    setup [:create_session]

    test "displays session", %{conn: conn, session: session} do
      {:ok, _show_live, html} = live(conn, Routes.session_show_path(conn, :show, session))

      assert html =~ "Show Session"
      assert html =~ session.name
    end

    test "updates session within modal", %{conn: conn, session: session} do
      {:ok, show_live, _html} = live(conn, Routes.session_show_path(conn, :show, session))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Session"

      assert_patch(show_live, Routes.session_show_path(conn, :edit, session))

      assert show_live
             |> form("#session-form", session: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#session-form", session: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.session_show_path(conn, :show, session))

      assert html =~ "Session updated successfully"
      assert html =~ "some updated name"
    end

    test "displays session updated from elsewhere", %{conn: conn, session: session} do
      {:ok, index_live, html} = live(conn, Routes.session_show_path(conn, :show, session))

      refute html =~ "some updated name"

      {:ok, _session} = Sessions.update_session(session, @update_attrs)

      assert render(index_live) =~ "some updated name"
    end

    test "removes session deleted from elsewhere", %{conn: conn, session: session} do
      {:ok, index_live, html} = live(conn, Routes.session_show_path(conn, :show, session))

      assert html =~ session.name

      {:ok, _session} = Sessions.delete_session(session)

      flash = assert_redirect index_live, Routes.session_index_path(conn, :index)
      assert flash["info"] == "Session was deleted"
    end
  end
end
