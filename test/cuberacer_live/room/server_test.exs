defmodule CuberacerLive.RoomServerTest do
  use CuberacerLive.DataCase, async: false

  import CuberacerLive.SessionsFixtures
  import CuberacerLive.AccountsFixtures
  import CuberacerLive.CubingFixtures

  alias CuberacerLive.{Sessions, Messaging}
  alias CuberacerLive.{RoomServer, RoomRegistry}

  setup do
    user = user_fixture()
    session = session_fixture()
    round = round_fixture(session_id: session.id)
    pid = start_supervised!({RoomServer, session})

    %{user: user, session: session, round: round, room_pid: pid}
  end

  test "create_round/1 adds a round to the session", %{session: session} do
    rounds_before = Sessions.list_rounds_of_session(session)
    scramble = RoomServer.create_round(session)
    rounds_after = Sessions.list_rounds_of_session(session)

    assert Enum.count(rounds_after) == Enum.count(rounds_before) + 1
    assert scramble == Sessions.get_current_round!(session).scramble
  end

  test "create_solve/4 adds a solve to the session", %{
    user: user,
    session: session,
    round: round
  } do
    Sessions.subscribe(session.id)
    penalty = penalty_fixture()
    RoomServer.create_solve(session, user, 1268, penalty)

    assert_receive {Sessions, [:solve, :created], solve}
    assert solve.id != nil
    assert solve.round_id == round.id
    assert solve.user_id == user.id
    assert solve.time == 1268
    assert solve.penalty_id == penalty.id
  end

  test "change_penalty/2 changes the penalty of the current solve for a user", %{
    user: user,
    session: session
  } do
    penalty_ok = penalty_fixture(name: "OK")
    penalty_dnf = penalty_fixture(name: "DNF")
    RoomServer.create_solve(session, user, 1268, penalty_ok)

    Sessions.subscribe(session.id)
    RoomServer.change_penalty(session, user, penalty_dnf)

    assert_receive {Sessions, [:solve, :updated], solve}
    assert solve.penalty_id == penalty_dnf.id
  end

  test "send_message/3 sends a message to the room", %{user: user, session: session} do
    Messaging.subscribe(session.id)
    RoomServer.send_message(session, user, "hey guys")

    assert_receive {Messaging, [:room_message, :created], room_message}
    assert room_message.id != nil
    assert room_message.user_id == user.id
    assert room_message.session_id == session.id
    assert room_message.message == "hey guys"
  end

  test "set_session_name/2 sets the session name and updates the registry", %{
    session: session,
    room_pid: pid
  } do
    Sessions.subscribe()
    RoomServer.set_session_name(session, "new session name")

    assert_receive {Sessions, [:session, :updated], updated_session}
    # TODO: Mock the registry?
    :timer.sleep(50)
    assert [%{session: ^updated_session}] = Registry.values(RoomRegistry, session.id, pid)
  end
end
