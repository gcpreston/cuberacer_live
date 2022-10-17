defmodule CuberacerLive.SessionsTest do
  use CuberacerLive.DataCase

  alias CuberacerLive.Sessions

  describe "sessions" do
    alias CuberacerLive.Accounts
    alias CuberacerLive.Accounts.UserRoomAuth
    alias CuberacerLive.Sessions.{Session, Round}

    import CuberacerLive.AccountsFixtures
    import CuberacerLive.SessionsFixtures
    import CuberacerLive.MessagingFixtures

    @invalid_attrs %{name: nil}

    test "list_sessions/0 returns all sessions" do
      session = session_fixture()
      assert Sessions.list_sessions() == [session]
    end

    test "list_user_sessions/1 returns all sessions with user solves, ordered desc" do
      user = user_fixture()
      session1 = session_fixture()
      _session2 = session_fixture()
      session3 = session_fixture()
      round1 = round_fixture(session: session1)
      _solve1 = solve_fixture(round_id: round1.id, user_id: user.id)
      round2 = round_fixture(session: session3)
      _solve2 = solve_fixture(round_id: round2.id, user_id: user.id)

      assert Sessions.list_user_sessions(user) == [session3, session1]
    end

    test "list_user_sessions/1 returns sessions where user has sent a message" do
      user = user_fixture()
      session = session_fixture()
      _message = room_message_fixture(session: session, user: user)

      assert Sessions.list_user_sessions(user) == [session]
    end

    test "list_user_sessions/1 returns sessions where user is host" do
      user = user_fixture()
      session = session_fixture(host_id: user.id)

      assert Sessions.list_user_sessions(user) == [session]
    end

    test "get_session!/1 returns the session with given id" do
      session = session_fixture()
      assert Sessions.get_session!(session.id) == session
    end

    test "get_session/1 returns the session with the given id" do
      session = session_fixture()
      assert Sessions.get_session(session.id) == session
    end

    test "get_session/1 returns nil if the session is not found" do
      assert Sessions.get_session(0) == nil
      assert Sessions.get_session("abc") == nil
      assert Sessions.get_session("abc123hi") == nil
    end

    test "create_session/1 with valid data creates a session" do
      valid_attrs = %{name: "some name", puzzle_type: :"3x3"}

      assert {:ok, %Session{} = session} = Sessions.create_session(valid_attrs)
      assert session.name == "some name"
      assert session.puzzle_type == :"3x3"
    end

    test "create_session/1 with no name returns error changeset" do
      invalid_attrs_nil = %{name: nil, puzzle_type: :"3x3"}
      invalid_attrs_empty = %{name: "", puzzle_type: :"3x3"}

      assert {:error, %Ecto.Changeset{}} = Sessions.create_session(invalid_attrs_nil)
      assert {:error, %Ecto.Changeset{}} = Sessions.create_session(invalid_attrs_empty)
    end

    test "create_session/1 with no cube type returns error changeset" do
      invalid_attrs = %{name: "some name", puzzle_type: nil}
      assert {:error, %Ecto.Changeset{}} = Sessions.create_session(invalid_attrs)
    end

    test "create_session/1 with a name too long returns error changeset" do
      invalid_attrs = %{
        name:
          "some really long name that is longer than a hundred characters because that's just overkill now isn't it",
        puzzle_type: :"3x3"
      }

      assert {:error, %Ecto.Changeset{}} = Sessions.create_session(invalid_attrs)
    end

    test "create_session/1 broadcasts to the context topic" do
      Sessions.subscribe()
      valid_attrs = %{name: "some name", puzzle_type: :"3x3"}
      {:ok, session} = Sessions.create_session(valid_attrs)

      assert_receive {Sessions, [:session, :created], ^session}
    end

    test "create_session/1 with invalid data does not broadcast" do
      Sessions.subscribe()
      {:error, _reason} = Sessions.create_session(@invalid_attrs)

      refute_receive {Sessions, _, _}
    end

    test "create_session_and_round/2 with valid data creates a session and a round" do
      assert {:ok, %Session{} = session, %Round{} = round} =
               Sessions.create_session_and_round("some name", :"2x2")

      assert session.name == "some name"
      assert session.puzzle_type == :"2x2"
      refute Sessions.private?(session)
      assert session.host_id == nil
      assert round.session_id == session.id
    end

    test "create_session_and_round/2 can be passed params for password and host" do
      user = user_fixture()

      assert {:ok, %Session{} = session, %Round{} = round} =
               Sessions.create_session_and_round("some name", :"4x4", "password123", user)

      assert session.name == "some name"
      assert session.puzzle_type == :"4x4"
      assert Sessions.private?(session)
      assert Session.valid_password?(session, "password123")
      assert session.host_id == user.id
      assert round.session_id == session.id
    end

    test "create_session_and_round/2 auto-authorizes the host of a private session" do
      user = user_fixture()
      {:ok, session, _round} = Sessions.create_session_and_round("some name", :"4x4", "password123", user)

      assert Accounts.user_authorized_for_room?(user, session)
    end

    test "create_session_and_round/2 does not create UserRoomAuth unless passed both password and host" do
      user = user_fixture()

      user_room_auth_count_before = Repo.one(from a in UserRoomAuth, select: count(a.id))
      {:ok, _session, _round} = Sessions.create_session_and_round("some name", :"4x4", "password123", nil)
      {:ok, _session, _round} = Sessions.create_session_and_round("some name", :"4x4", nil, user)
      user_room_auth_count_after = Repo.one(from a in UserRoomAuth, select: count(a.id))

      assert user_room_auth_count_before == user_room_auth_count_after
    end

    test "create_session_and_round/2 with no name returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sessions.create_session_and_round(nil, :Megaminx)
    end

    test "create_session_and_round/2 with no cube type returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sessions.create_session_and_round("some name", nil)
    end

    test "create_session_and_round/2 broadcasts to the context topic" do
      Sessions.subscribe()
      {:ok, session, _round} = Sessions.create_session_and_round("some name", :Skewb)

      assert_receive {Sessions, [:session, :created], ^session}
      # NOTE: The round should also be broadcasted, but only to the session topic, which
      # can't be subscribed to in time because create_session_and_round/2 is synchronous.
      # This is not relevant to the use case of the function, and there are separate tests
      # for this functionality of create_round/2, so I'm not concerned about it.
    end

    test "create_session_and_round/2 with invalid data does not broadcast" do
      Sessions.subscribe()
      {:error, _reason} = Sessions.create_session_and_round("some name", nil)

      refute_receive {Sessions, _, _}
    end

    test "private?/1 determines if a session is private" do
      public_session = session_fixture(password: nil)
      private_session = session_fixture(password: "hello")

      refute Sessions.private?(public_session)
      assert Sessions.private?(private_session)
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
      round1 = round_fixture(session: session)
      round2 = round_fixture(session: session)
      _solve1 = solve_fixture(round_id: round1.id)
      _solve2 = solve_fixture(round_id: round1.id)
      _solve3 = solve_fixture(round_id: round2.id)

      actual_rounds = Sessions.list_rounds_of_session(session)
      assert Enum.map(actual_rounds, & &1.id) == [round1.id, round2.id]

      Enum.each(actual_rounds, fn round ->
        assert Ecto.assoc_loaded?(round.solves)
      end)
    end

    test "list_rounds_of_session/3 descending order" do
      session = session_fixture()
      round1 = round_fixture(session: session)
      round2 = round_fixture(session: session)

      actual_rounds = Sessions.list_rounds_of_session(session, :desc)
      assert Enum.map(actual_rounds, & &1.id) == [round2.id, round1.id]
    end

    test "get_round!/1 returns the round with given id" do
      round = round_fixture()
      assert Sessions.get_round!(round.id) == round
    end

    test "get_current_round/1 gets the current round" do
      session = session_fixture()
      _round1 = round_fixture(session: session)
      round2 = round_fixture(session: session)

      assert Sessions.get_current_round!(session) == round2
    end

    test "create_round/2 with valid data creates a round" do
      session = session_fixture()

      assert {:ok, %Round{} = round} = Sessions.create_round(session)
      assert round.scramble != nil
      assert round.session_id == session.id
    end

    test "create_round/2 can be passed a scramble" do
      session = session_fixture()
      scramble = Whisk.scramble("3x3")

      assert {:ok, %Round{} = round} = Sessions.create_round(session, scramble)
      assert round.scramble == scramble
      assert round.session_id == session.id
    end

    test "create_round/2 with invalid data returns error changeset" do
      session = session_fixture()
      assert {:error, %Ecto.Changeset{}} = Sessions.create_round(session, true)
    end

    test "create_round/2 broadcasts to the session topic" do
      session = session_fixture()
      Sessions.subscribe(session.id)
      {:ok, round} = Sessions.create_round(session)

      assert_receive {Sessions, [:round, :created], ^round}
    end

    test "create_round/2 does not broadcast to the context topic" do
      session = session_fixture()
      Sessions.subscribe()
      {:ok, _round} = Sessions.create_round(session)

      refute_receive {Sessions, _, _}
    end

    test "create_round/2 with invalid data does not broadcast" do
      session = session_fixture()
      Sessions.subscribe()
      Sessions.subscribe(session.id)
      {:error, _reason} = Sessions.create_round(session, true)

      refute_receive {Sessions, _, _}
    end

    test "create_round_debounced/2 twice too quick returns an error" do
      session = session_fixture()
      _round = round_fixture(session: session)

      Sessions.create_round_debounced(session)
      assert {:error, :too_soon} = Sessions.create_round_debounced(session)
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
    import CuberacerLive.SessionsFixtures

    # NOTE: Solve results must be preloaded with :round to be checked against
    #   fixture structs. This is because the fixture gets preloaded with :round
    #   in notify_subscribers, and it seems preferrable to assert on the object
    #   than just the solve ID when possible.

    test "list_solves/0 returns all solves" do
      solve = solve_fixture()
      assert Enum.map(Sessions.list_solves(), &Repo.preload(&1, :round)) == [solve]
    end

    test "get_solve!/1 returns the solve with given id" do
      solve = solve_fixture()
      assert Sessions.get_solve!(solve.id) |> Repo.preload(:round) == solve
    end

    test "get_current_solve/2 gets the solve of the current round" do
      user1 = user_fixture()
      user2 = user_fixture()

      session = session_fixture()
      round1 = round_fixture(session: session)
      _solve1 = solve_fixture(round_id: round1.id, user_id: user1.id)
      _solve2 = solve_fixture(round_id: round1.id, user_id: user2.id)

      round2 = round_fixture(session: session)
      solve3 = solve_fixture(round_id: round2.id, user_id: user1.id)

      assert Sessions.get_current_solve(session, user1) |> Repo.preload(:round) == solve3
      assert Sessions.get_current_solve(session, user2) == nil
    end

    # TODO: create_solve/4 tests, get rid of create_solve/1?

    test "create_solve/1 with valid data creates a solve" do
      user = user_fixture()
      round = round_fixture()

      valid_attrs = %{time: 42, user_id: user.id, penalty: :OK, round_id: round.id}

      assert {:ok, %Solve{} = solve} = Sessions.create_solve(valid_attrs)
      assert solve.time == 42
      assert solve.user_id == user.id
      assert solve.penalty == :OK
      assert solve.round_id == round.id
    end

    test "create_solve/1 with no time returns error changeset" do
      user = user_fixture()
      round = round_fixture()
      invalid_attrs = %{time: nil, penalty: :"3x3", user_id: user.id, round_id: round.id}

      assert {:error, %Ecto.Changeset{}} = Sessions.create_solve(invalid_attrs)
    end

    test "create_solve/1 with no user returns error changeset" do
      round = round_fixture()
      invalid_attrs = %{time: nil, user_id: nil, penalty: :OK, round_id: round.id}

      assert {:error, %Ecto.Changeset{}} = Sessions.create_solve(invalid_attrs)
    end

    test "create_solve/1 with no penalty returns error changeset" do
      user = user_fixture()
      round = round_fixture()
      invalid_attrs = %{time: nil, user_id: user.id, penalty: nil, round_id: round.id}

      assert {:error, %Ecto.Changeset{}} = Sessions.create_solve(invalid_attrs)
    end

    test "create_solve/1 with no round returns error changeset" do
      user = user_fixture()
      invalid_attrs = %{time: nil, user_id: user.id, penalty: :"3x3", round_id: nil}

      assert {:error, %Ecto.Changeset{}} = Sessions.create_solve(invalid_attrs)
    end

    test "create_solve/1 does not allow one user to submit multiple solves in a round" do
      user = user_fixture()
      round = round_fixture()
      valid_attrs = %{time: 42, user_id: user.id, penalty: :OK, round_id: round.id}

      assert {:ok, _} = Sessions.create_solve(valid_attrs)

      assert {:error, %Ecto.Changeset{errors: [user_id_round_id: {message, _info}]}} =
               Sessions.create_solve(valid_attrs)

      assert message == "user has already submitted a time for this round"
    end

    test "create_solve/1 broadcasts to the session topic" do
      round = round_fixture()
      user = user_fixture()

      Sessions.subscribe(round.session_id)
      valid_attrs = %{time: 42, penalty: :OK, user_id: user.id, round_id: round.id}
      {:ok, solve} = Sessions.create_solve(valid_attrs)

      assert_receive {Sessions, [:solve, :created], ^solve}
    end

    test "create_solve/1 does not broadcast to context topic" do
      round = round_fixture()
      user = user_fixture()

      Sessions.subscribe()
      valid_attrs = %{time: 42, penalty: :OK, user_id: user.id, round_id: round.id}
      {:ok, _solve} = Sessions.create_solve(valid_attrs)

      refute_receive {Sessions, _, _}
    end

    test "create_solve/1 with invalid data does not broadcast" do
      round = round_fixture()
      user = user_fixture()

      Sessions.subscribe()
      Sessions.subscribe(round.session_id)
      invalid_attrs = %{time: nil, penalty: :OK, user_id: user.id, round_id: round.id}
      {:error, _reason} = Sessions.create_solve(invalid_attrs)

      refute_receive {Sessions, _, _}
    end

    test "change_penalty/2 with valid data updates the solve" do
      solve = solve_fixture()

      assert {:ok, %Solve{} = solve} = Sessions.change_penalty(solve, :"+2")
      assert solve.penalty == :"+2"
      solve = Sessions.get_solve!(solve.id)
      assert solve.penalty == :"+2"
    end

    test "change_penalty/2 broadcasts to session topic" do
      solve = solve_fixture() |> Repo.preload(:session)
      Sessions.subscribe(solve.session.id)

      assert {:ok, solve} = Sessions.change_penalty(solve, :DNF)
      assert_receive {Sessions, [:solve, :updated], ^solve}
    end

    test "change_penalty/2 does not broadcast to context topic" do
      solve = solve_fixture()
      Sessions.subscribe()

      assert {:ok, _solve} = Sessions.change_penalty(solve, :DNF)
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
      solve = solve_fixture(time: 12340, penalty: :"+2")
      assert Sessions.display_solve(solve) == "14.340+"
    end

    test "display_solve/1 DNF" do
      solve = solve_fixture(time: 12340, penalty: :DNF)
      assert Sessions.display_solve(solve) == "DNF"
    end

    test "display_solve/1 long" do
      solve = solve_fixture(time: 127_038, penalty: :OK)
      assert Sessions.display_solve(solve) == "2:07.038"
    end

    test "current_stats/2 calculates ao5 and ao12" do
      user1 = user_fixture()
      user2 = user_fixture()

      session = session_fixture()
      round1 = round_fixture(session: session)

      assert %{ao5: :dnf, ao12: :dnf} = Sessions.current_stats(session, user1)
      assert %{ao5: :dnf, ao12: :dnf} = Sessions.current_stats(session, user2)

      # Rounds 1-4

      solve1_1 = solve_fixture(round_id: round1.id, user_id: user1.id, time: 9168)
      solve1_2 = solve_fixture(round_id: round1.id, user_id: user2.id, time: 7842)

      round2 = round_fixture(session: session)
      solve2_1 = solve_fixture(round_id: round2.id, user_id: user1.id, time: 14003)
      solve2_2 = solve_fixture(round_id: round2.id, user_id: user2.id, time: 3153)

      round3 = round_fixture(session: session)
      solve3_1 = solve_fixture(round_id: round3.id, user_id: user1.id, time: 12433)
      solve3_2 = solve_fixture(round_id: round3.id, user_id: user2.id, time: 5099)

      round4 = round_fixture(session: session)
      solve4_2 = solve_fixture(round_id: round4.id, user_id: user2.id, time: 3209)

      assert %{ao5: :dnf, ao12: :dnf} = Sessions.current_stats(session, user1)
      assert %{ao5: :dnf, ao12: :dnf} = Sessions.current_stats(session, user2)

      # Round 5

      round5 = round_fixture(session: session)

      assert %{ao5: :dnf} = Sessions.current_stats(session, user2)

      solve5_1 = solve_fixture(round_id: round5.id, user_id: user1.id, time: 17359)
      solve5_2 = solve_fixture(round_id: round5.id, user_id: user2.id, time: 14178)

      user1_stats = Sessions.current_stats(session, user1)
      user2_stats = Sessions.current_stats(session, user2)

      assert user1_stats.ao5 == (solve2_1.time + solve3_1.time + solve5_1.time) / 3
      assert user2_stats.ao5 == (solve1_2.time + solve3_2.time + solve4_2.time) / 3
      assert user1_stats.ao12 == :dnf
      assert user2_stats.ao12 == :dnf

      # Round 6

      round6 = round_fixture(session: session)
      solve6_1 = solve_fixture(round_id: round6.id, user_id: user1.id, time: 14885)
      solve6_2 = solve_fixture(round_id: round6.id, user_id: user2.id, time: 13499)

      user1_stats = Sessions.current_stats(session, user1)
      user2_stats = Sessions.current_stats(session, user2)

      assert user1_stats.ao5 == (solve2_1.time + solve5_1.time + solve6_1.time) / 3
      assert user2_stats.ao5 == (solve3_2.time + solve4_2.time + solve6_2.time) / 3
      assert user1_stats.ao12 == :dnf
      assert user2_stats.ao12 == :dnf

      # Rounds 7-11

      round7 = round_fixture(session: session)
      solve7_1 = solve_fixture(round_id: round7.id, user_id: user1.id, time: 17033)
      _solve7_2 = solve_fixture(round_id: round7.id, user_id: user2.id, time: 1296)

      round8 = round_fixture(session: session)
      _solve8_1 = solve_fixture(round_id: round8.id, user_id: user1.id, time: 3283)
      solve8_2 = solve_fixture(round_id: round8.id, user_id: user2.id, time: 12279)

      round9 = round_fixture(session: session)
      solve9_1 = solve_fixture(round_id: round9.id, user_id: user1.id, time: 12043)
      solve9_2 = solve_fixture(round_id: round9.id, user_id: user2.id, time: 16650)

      round10 = round_fixture(session: session)
      solve10_1 = solve_fixture(round_id: round10.id, user_id: user1.id, time: 19722)
      solve10_2 = solve_fixture(round_id: round10.id, user_id: user2.id, time: 19707)

      round11 = round_fixture(session: session)

      solve11_1 =
        solve_fixture(
          round_id: round11.id,
          user_id: user1.id,
          time: 2142,
          penalty: :"+2"
        )

      _solve11_2 =
        solve_fixture(
          round_id: round11.id,
          user_id: user2.id,
          time: 15975,
          penalty: :DNF
        )

      user1_stats = Sessions.current_stats(session, user1)
      user2_stats = Sessions.current_stats(session, user2)

      assert user1_stats.ao5 ==
               (solve7_1.time + solve9_1.time + Sessions.actual_time(solve11_1)) / 3

      assert user2_stats.ao5 == (solve8_2.time + solve9_2.time + solve10_2.time) / 3
      assert user1_stats.ao12 == :dnf
      assert user2_stats.ao12 == :dnf

      # Round 12

      round12 = round_fixture(session: session)
      solve12_1 = solve_fixture(round_id: round12.id, user_id: user1.id, time: 8484)
      solve12_2 = solve_fixture(round_id: round12.id, user_id: user2.id, time: 11910)

      user1_stats = Sessions.current_stats(session, user1)
      user2_stats = Sessions.current_stats(session, user2)

      assert user1_stats.ao5 ==
               (solve9_1.time + Sessions.actual_time(solve11_1) + solve12_1.time) / 3

      assert user2_stats.ao5 == (solve8_2.time + solve9_2.time + solve10_2.time) / 3

      assert user1_stats.ao12 ==
               (solve1_1.time + solve2_1.time + solve3_1.time + solve5_1.time +
                  solve6_1.time + solve7_1.time + solve9_1.time + solve10_1.time +
                  Sessions.actual_time(solve11_1) + solve12_1.time) / 10

      assert user2_stats.ao12 ==
               (solve1_2.time + solve2_2.time + solve3_2.time + solve4_2.time + solve5_2.time +
                  solve6_2.time + solve8_2.time + solve9_2.time + solve10_2.time + solve12_2.time) /
                 10

      # Round 13

      round13 = round_fixture(session: session)

      _solve13_1 =
        solve_fixture(
          round_id: round13.id,
          user_id: user1.id,
          time: 5705,
          penalty: :DNF
        )

      _solve13_2 =
        solve_fixture(
          round_id: round13.id,
          user_id: user2.id,
          time: 9661,
          penalty: :DNF
        )

      user1_stats = Sessions.current_stats(session, user1)
      user2_stats = Sessions.current_stats(session, user2)

      assert user1_stats.ao5 == (solve9_1.time + solve10_1.time + solve12_1.time) / 3
      assert user2_stats.ao5 == :dnf
      assert user1_stats.ao12 == :dnf
      assert user2_stats.ao12 == :dnf
    end
  end
end
