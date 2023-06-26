defmodule CuberacerLive.RoomTest do
  use CuberacerLive.DataCase

  alias CuberacerLive.RoomCache
  alias CuberacerLive.{Events, Room, Sessions}
  alias CuberacerLive.Accounts.User

  import CuberacerLive.SessionsFixtures
  import CuberacerLive.AccountsFixtures

  setup do
    {:ok, pid, session} = RoomCache.create_room("test room", :"3x3")
    user = user_fixture()
    send(pid, {CuberacerLive.PresenceClient, %Events.JoinRoom{user_data: %{user: user}}})
    Room.subscribe(session)

    %{session: session, user: user, pid: pid}
  end

  describe "set_time_entry/3" do
    test "broadcasts an event", %{session: session, user: %User{id: user_id} = user} do
      Room.set_time_entry(session, user, :keyboard)

      assert_receive {Room,
                      %Events.TimeEntryMethodSet{user_id: ^user_id, entry_method: :keyboard}}
    end
  end

  describe "solving/2" do
    test "broadcasts an event", %{session: session, user: %User{id: user_id} = user} do
      Room.solving(session, user)

      assert_receive {Room, %Events.Solving{user_id: ^user_id}}
    end
  end

  describe "alive?/1" do
    test "determines if a room server process associated with the session exists" do
      dead_session = session_fixture()
      {:ok, _pid, alive_session} = RoomCache.create_room("test room", :"3x3")

      refute Room.alive?(dead_session)
      assert Room.alive?(alive_session)
    end
  end

  describe "change_penalty/3" do
    test "changes the penalty of the current round's solve", %{session: session, user: user} do
      Room.create_solve(session, user, 42, :OK)
      Room.change_penalty(session, user, :"+2")

      current_solve = Sessions.get_current_solve(session, user)

      assert current_solve.penalty == :"+2"
    end

    test "does nothing if the user has no solve for the current round", %{
      session: session,
      user: user
    } do
      Room.change_penalty(session, user, :"+2")

      assert Sessions.get_current_solve(session, user) == nil
    end
  end
end
