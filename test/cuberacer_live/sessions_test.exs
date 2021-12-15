defmodule CuberacerLive.SessionsTest do
  use CuberacerLive.DataCase

  alias CuberacerLive.Sessions

  describe "sessions" do
    alias CuberacerLive.Sessions.Session

    import CuberacerLive.SessionsFixtures

    @invalid_attrs %{name: nil}

    test "list_sessions/0 returns all sessions" do
      session = session_fixture()
      assert Sessions.list_sessions() == [session]
    end

    test "get_session!/1 returns the session with given id" do
      session = session_fixture()
      assert Sessions.get_session!(session.id) == session
    end

    test "create_session/1 with valid data creates a session" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Session{} = session} = Sessions.create_session(valid_attrs)
      assert session.name == "some name"
    end

    test "create_session/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sessions.create_session(@invalid_attrs)
    end

    test "create_session/1 broadcasts to the context topic" do
      Sessions.subscribe()
      valid_attrs = %{name: "some name"}
      {:ok, session} = Sessions.create_session(valid_attrs)

      assert_receive {Sessions, [:session, :created], ^session}
    end

    test "create_session/1 with invalid data does not broadcast" do
      Sessions.subscribe()
      Sessions.create_session(@invalid_attrs)

      refute_receive {Sessions, _, _}
    end

    test "update_session/2 with valid data updates the session" do
      session = session_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Session{} = session} = Sessions.update_session(session, update_attrs)
      assert session.name == "some updated name"
    end

    test "update_session/2 with invalid data returns error changeset" do
      session = session_fixture()
      assert {:error, %Ecto.Changeset{}} = Sessions.update_session(session, @invalid_attrs)
      assert session == Sessions.get_session!(session.id)
    end

    test "update_session/2 broadcasts to the context topic" do
      Sessions.subscribe()
      session = session_fixture()
      update_attrs = %{name: "some updated name"}
      {:ok, session} = Sessions.update_session(session, update_attrs)

      assert_receive {Sessions, [:session, :updated], ^session}
    end

    test "update_session/2 broadcasts to the session topic" do
      session = session_fixture()
      Sessions.subscribe(session.id)
      update_attrs = %{name: "some updated name"}
      {:ok, session} = Sessions.update_session(session, update_attrs)

      assert_receive {Sessions, [:session, :updated], ^session}
    end

    test "update_session/2 does not broadcast to other session topics" do
      session = session_fixture()
      Sessions.subscribe(session.id - 1)
      update_attrs = %{name: "some updated name"}
      Sessions.update_session(session, update_attrs)

      refute_receive {Sessions, _, _}
    end

    test "update_session/2 with invalid data does not broadcast" do
      session = session_fixture()
      Sessions.subscribe()
      Sessions.subscribe(session.id)
      Sessions.update_session(session, @invalid_attrs)

      refute_receive {Sessions, _, _}
    end

    test "delete_session/1 deletes the session" do
      session = session_fixture()
      assert {:ok, %Session{}} = Sessions.delete_session(session)
      assert_raise Ecto.NoResultsError, fn -> Sessions.get_session!(session.id) end
    end

    test "delete_session/1 broadcasts to the context topic" do
      Sessions.subscribe()
      session = session_fixture()
      {:ok, session} = Sessions.delete_session(session)

      assert_receive {Sessions, [:session, :deleted], ^session}
    end

    test "delete_session/1 broadcasts to the session topic" do
      session = session_fixture()
      Sessions.subscribe(session.id)
      {:ok, session} = Sessions.delete_session(session)

      assert_receive {Sessions, [:session, :deleted], ^session}
    end

    test "delete_session/1 does not broadcast to other session topics" do
      session = session_fixture()
      Sessions.subscribe(session.id - 1)
      Sessions.delete_session(session)

      refute_receive {Sessions, _, _}
    end

    test "change_session/1 returns a session changeset" do
      session = session_fixture()
      assert %Ecto.Changeset{} = Sessions.change_session(session)
    end
  end
end
