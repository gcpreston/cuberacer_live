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
      {:error, _reason} = Sessions.create_session(@invalid_attrs)

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
      {:ok, _session} = Sessions.update_session(session, update_attrs)

      refute_receive {Sessions, _, _}
    end

    test "update_session/2 with invalid data does not broadcast" do
      session = session_fixture()
      Sessions.subscribe()
      Sessions.subscribe(session.id)
      {:error, _reason} = Sessions.update_session(session, @invalid_attrs)

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

    test "list_rounds/0 returns all rounds" do
      round = round_fixture()
      assert Sessions.list_rounds() == [round]
    end

    test "list_rounds_of_session/3 returns all rounds of a session, preloaded" do
      session = session_fixture()
      round1 = round_fixture(session_id: session.id)
      round2 = round_fixture(session_id: session.id)
      _solve1 = solve_fixture(round_id: round1.id)
      _solve2 = solve_fixture(round_id: round1.id)
      _solve3 = solve_fixture(round_id: round2.id)

      actual_rounds = Sessions.list_rounds_of_session(session)
      assert Enum.map(actual_rounds, & &1.id) == [round1.id, round2.id]

      Enum.each(actual_rounds, fn round ->
        assert Ecto.assoc_loaded?(round.solves)

        Enum.each(round.solves, fn solve ->
          assert Ecto.assoc_loaded?(solve.penalty)
        end)
      end)
    end

    test "list_rounds_of_session/3 descending order" do
      session = session_fixture()
      round1 = round_fixture(session_id: session.id)
      round2 = round_fixture(session_id: session.id)

      actual_rounds = Sessions.list_rounds_of_session(session, :desc)
      assert Enum.map(actual_rounds, & &1.id) == [round2.id, round1.id]
    end

    test "get_round!/1 returns the round with given id" do
      round = round_fixture()
      assert Sessions.get_round!(round.id) == round
    end

    test "get_current_round/1 gets the current round" do
      session = session_fixture()
      _round1 = round_fixture(session_id: session.id)
      round2 = round_fixture(session_id: session.id)

      assert Sessions.get_current_round!(session) == round2
    end

    test "create_round/1 with valid data creates a round" do
      session = session_fixture()

      valid_attrs = %{scramble: "some scramble", session_id: session.id}

      assert {:ok, %Round{} = round} = Sessions.create_round(valid_attrs)
      assert round.scramble == "some scramble"
      assert round.session_id == session.id
    end

    test "create_round/1 with no scramble returns error changeset" do
      session = session_fixture()

      invalid_attrs = %{scramble: nil, session_id: session.id}

      assert {:error, %Ecto.Changeset{}} = Sessions.create_round(invalid_attrs)
    end

    test "create_round/1 with no session returns error changeset" do
      invalid_attrs = %{scramble: "some scramble", session_id: nil}

      assert {:error, %Ecto.Changeset{}} = Sessions.create_round(invalid_attrs)
    end

    test "create_round/1 broadcasts to the session topic" do
      session = session_fixture()
      Sessions.subscribe(session.id)
      valid_attrs = %{scramble: "some scramble", session_id: session.id}
      {:ok, round} = Sessions.create_round(valid_attrs)

      assert_receive {Sessions, [:round, :created], ^round}
    end

    test "create_round/1 does not broadcast to the context topic" do
      session = session_fixture()
      Sessions.subscribe()
      valid_attrs = %{scramble: "some scramble", session_id: session.id}
      {:ok, _round} = Sessions.create_round(valid_attrs)

      refute_receive {Sessions, _, _}
    end

    test "create_round/1 with invalid data does not broadcast" do
      session = session_fixture()
      Sessions.subscribe()
      Sessions.subscribe(session.id)
      invalid_attrs = %{scramble: nil, session_id: session.id}
      {:error, _reason} = Sessions.create_round(invalid_attrs)

      refute_receive {Sessions, _, _}
    end

    test "delete_round/1 deletes the round" do
      round = round_fixture()
      assert {:ok, %Round{}} = Sessions.delete_round(round)
      assert_raise Ecto.NoResultsError, fn -> Sessions.get_round!(round.id) end
    end

    test "delete_round/1 broadcasts to the session topic" do
      round = round_fixture()
      Sessions.subscribe(round.session_id)
      {:ok, round} = Sessions.delete_round(round)

      assert_receive {Sessions, [:round, :deleted], ^round}
    end

    test "delete_round/1 does not broadcast to the context topic" do
      round = round_fixture()
      Sessions.subscribe()
      {:ok, _round} = Sessions.delete_round(round)

      refute_receive {Sessions, _, _}
    end
  end

  describe "solves" do
    alias CuberacerLive.Sessions.Solve

    import CuberacerLive.AccountsFixtures
    import CuberacerLive.CubingFixtures
    import CuberacerLive.SessionsFixtures

    test "list_solves/0 returns all solves" do
      solve = solve_fixture()
      assert Sessions.list_solves() == [solve]
    end

    test "get_solve!/1 returns the solve with given id" do
      solve = solve_fixture()
      assert Sessions.get_solve!(solve.id) == solve
    end

    test "get_current_solve/2 gets the solve of the current round" do
      user1 = user_fixture()
      user2 = user_fixture()

      session = session_fixture()
      round1 = round_fixture(session_id: session.id)
      _solve1 = solve_fixture(round_id: round1.id, user_id: user1.id)
      _solve2 = solve_fixture(round_id: round1.id, user_id: user2.id)

      round2 = round_fixture(session_id: session.id)
      solve3 = solve_fixture(round_id: round2.id, user_id: user1.id)

      assert Sessions.get_current_solve(session, user1) == solve3
      assert Sessions.get_current_solve(session, user2) == nil
    end

    # TODO: create_solve/4 tests, get rid of create_solve/1?

    test "create_solve/1 with valid data creates a solve" do
      user = user_fixture()
      penalty = penalty_fixture()
      round = round_fixture()

      valid_attrs = %{time: 42, user_id: user.id, penalty_id: penalty.id, round_id: round.id}

      assert {:ok, %Solve{} = solve} = Sessions.create_solve(valid_attrs)
      assert solve.time == 42
      assert solve.user_id == user.id
      assert solve.penalty_id == penalty.id
      assert solve.round_id == round.id
    end

    test "create_solve/1 with no time returns error changeset" do
      user = user_fixture()
      penalty = penalty_fixture()
      round = round_fixture()

      invalid_attrs = %{time: nil, user_id: user.id, penalty_id: penalty.id, round_id: round.id}

      assert {:error, %Ecto.Changeset{}} = Sessions.create_solve(invalid_attrs)
    end

    test "create_solve/1 with no user returns error changeset" do
      penalty = penalty_fixture()
      round = round_fixture()

      invalid_attrs = %{time: nil, user_id: nil, penalty_id: penalty.id, round_id: round.id}

      assert {:error, %Ecto.Changeset{}} = Sessions.create_solve(invalid_attrs)
    end

    test "create_solve/1 with no penalty returns error changeset" do
      user = user_fixture()
      round = round_fixture()

      invalid_attrs = %{time: nil, user_id: user.id, penalty_id: nil, round_id: round.id}

      assert {:error, %Ecto.Changeset{}} = Sessions.create_solve(invalid_attrs)
    end

    test "create_solve/1 with no round returns error changeset" do
      user = user_fixture()
      penalty = penalty_fixture()

      invalid_attrs = %{time: nil, user_id: user.id, penalty_id: penalty.id, round_id: nil}

      assert {:error, %Ecto.Changeset{}} = Sessions.create_solve(invalid_attrs)
    end

    test "create_solve/1 does not allow one user to submit multiple solves in a round" do
      user = user_fixture()
      penalty = penalty_fixture()
      round = round_fixture()

      valid_attrs = %{time: 42, user_id: user.id, penalty_id: penalty.id, round_id: round.id}

      assert {:ok, _} = Sessions.create_solve(valid_attrs)

      assert {:error, %Ecto.Changeset{errors: [user_id_round_id: {message, _info}]}} =
               Sessions.create_solve(valid_attrs)

      assert message == "user has already submitted a time for this round"
    end

    test "create_solve/1 broadcasts to the session topic" do
      round = round_fixture()
      user = user_fixture()
      penalty = penalty_fixture()

      Sessions.subscribe(round.session_id)
      valid_attrs = %{time: 42, user_id: user.id, penalty_id: penalty.id, round_id: round.id}
      {:ok, solve} = Sessions.create_solve(valid_attrs)

      assert_receive {Sessions, [:solve, :created], ^solve}
    end

    test "create_solve/1 does not broadcast to context topic" do
      round = round_fixture()
      user = user_fixture()
      penalty = penalty_fixture()

      Sessions.subscribe()
      valid_attrs = %{time: 42, user_id: user.id, penalty_id: penalty.id, round_id: round.id}
      {:ok, _solve} = Sessions.create_solve(valid_attrs)

      refute_receive {Sessions, _, _}
    end

    test "create_solve/1 with invalid data does not broadcast" do
      round = round_fixture()
      user = user_fixture()
      penalty = penalty_fixture()

      Sessions.subscribe()
      Sessions.subscribe(round.session_id)
      valid_attrs = %{time: nil, user_id: user.id, penalty_id: penalty.id, round_id: round.id}
      {:error, _reason} = Sessions.create_solve(valid_attrs)

      refute_receive {Sessions, _, _}
    end

    test "change_penalty/2 with valid data updates the solve" do
      solve = solve_fixture()
      penalty = penalty_fixture()

      assert {:ok, %Solve{} = solve} = Sessions.change_penalty(solve, penalty)
      assert solve.penalty_id == penalty.id
    end

    test "change_penalty/2 broadcasts to session topic" do
      penalty = penalty_fixture()
      solve = solve_fixture() |> Repo.preload(:session)
      Sessions.subscribe(solve.session.id)

      assert {:ok, solve} = Sessions.change_penalty(solve, penalty)
      assert_receive {Sessions, [:solve, :updated], ^solve}
    end

    test "change_penalty/2 does not broadcast to context topic" do
      penalty = penalty_fixture()
      solve = solve_fixture()
      Sessions.subscribe()

      assert {:ok, _solve} = Sessions.change_penalty(solve, penalty)
      refute_receive {Sessions, _, _}
    end

    test "delete_solve/1 deletes the solve" do
      solve = solve_fixture()
      assert {:ok, %Solve{}} = Sessions.delete_solve(solve)
      assert_raise Ecto.NoResultsError, fn -> Sessions.get_solve!(solve.id) end
    end

    test "delete_solve/1 broadcasts to the session topic" do
      solve = solve_fixture() |> Repo.preload(:session)
      Sessions.subscribe(solve.session.id)

      assert {:ok, solve} = Sessions.delete_solve(solve)
      assert_receive {Sessions, [:solve, :deleted], ^solve}
    end

    test "delete_solve/1 does not broadcast to context topic" do
      solve = solve_fixture()
      Sessions.subscribe()

      assert {:ok, _solve} = Sessions.delete_solve(solve)
      refute_receive {Sessions, _, _}
    end

    test "display_solve/1 OK" do
      solve = solve_fixture(time: 12340)

      assert Sessions.display_solve(solve) == "12.340"
    end

    test "display_solve/1 +2" do
      penalty = penalty_fixture(name: "+2")
      solve = solve_fixture(time: 12340, penalty_id: penalty.id)

      assert Sessions.display_solve(solve) == "14.340+"
    end

    test "display_solve/1 DNF" do
      penalty = penalty_fixture(name: "DNF")
      solve = solve_fixture(time: 12340, penalty_id: penalty.id)

      assert Sessions.display_solve(solve) == "DNF"
    end
  end
end
