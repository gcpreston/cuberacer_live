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

  describe "rounds" do
    alias CuberacerLive.Sessions.Round

    import CuberacerLive.SessionsFixtures

    @invalid_attrs %{scramble: nil}

    test "list_rounds/0 returns all rounds" do
      round = round_fixture()
      assert Sessions.list_rounds() == [round]
    end

    test "get_round!/1 returns the round with given id" do
      round = round_fixture()
      assert Sessions.get_round!(round.id) == round
    end

    test "create_round/1 with valid data creates a round" do
      valid_attrs = %{scramble: "some scramble"}

      assert {:ok, %Round{} = round} = Sessions.create_round(valid_attrs)
      assert round.scramble == "some scramble"
    end

    test "create_round/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sessions.create_round(@invalid_attrs)
    end

    test "update_round/2 with valid data updates the round" do
      round = round_fixture()
      update_attrs = %{scramble: "some updated scramble"}

      assert {:ok, %Round{} = round} = Sessions.update_round(round, update_attrs)
      assert round.scramble == "some updated scramble"
    end

    test "update_round/2 with invalid data returns error changeset" do
      round = round_fixture()
      assert {:error, %Ecto.Changeset{}} = Sessions.update_round(round, @invalid_attrs)
      assert round == Sessions.get_round!(round.id)
    end

    test "delete_round/1 deletes the round" do
      round = round_fixture()
      assert {:ok, %Round{}} = Sessions.delete_round(round)
      assert_raise Ecto.NoResultsError, fn -> Sessions.get_round!(round.id) end
    end

    test "change_round/1 returns a round changeset" do
      round = round_fixture()
      assert %Ecto.Changeset{} = Sessions.change_round(round)
    end
  end

  describe "solves" do
    alias CuberacerLive.Sessions.Solve

    import CuberacerLive.AccountsFixtures
    import CuberacerLive.SessionsFixtures

    @invalid_attrs %{time: nil}

    test "list_solves/0 returns all solves" do
      solve = solve_fixture()
      assert Sessions.list_solves() == [solve]
    end

    test "get_solve!/1 returns the solve with given id" do
      solve = solve_fixture()
      assert Sessions.get_solve!(solve.id) == solve
    end

    test "create_solve/1 with valid data creates a solve" do
      valid_attrs = %{time: 42}

      assert {:ok, %Solve{} = solve} = Sessions.create_solve(valid_attrs)
      assert solve.time == 42
    end

    test "create_solve/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sessions.create_solve(@invalid_attrs)
    end

    test "update_solve/2 with valid data updates the solve" do
      solve = solve_fixture()
      update_attrs = %{time: 43}

      assert {:ok, %Solve{} = solve} = Sessions.update_solve(solve, update_attrs)
      assert solve.time == 43
    end

    test "update_solve/2 with invalid data returns error changeset" do
      solve = solve_fixture()
      assert {:error, %Ecto.Changeset{}} = Sessions.update_solve(solve, @invalid_attrs)
      assert solve == Sessions.get_solve!(solve.id)
    end

    test "delete_solve/1 deletes the solve" do
      solve = solve_fixture()
      assert {:ok, %Solve{}} = Sessions.delete_solve(solve)
      assert_raise Ecto.NoResultsError, fn -> Sessions.get_solve!(solve.id) end
    end

    test "change_solve/1 returns a solve changeset" do
      solve = solve_fixture()
      assert %Ecto.Changeset{} = Sessions.change_solve(solve)
    end
  end
end
