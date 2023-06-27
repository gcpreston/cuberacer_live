defmodule CuberacerLive.RoomServerTest do
  use CuberacerLive.DataCase, async: false

  alias CuberacerLive.ParticipantDataEntry
  alias CuberacerLive.{Events, RoomCache, RoomServer, Room}

  import CuberacerLive.SessionsFixtures
  import CuberacerLive.AccountsFixtures

  describe "get_participant_data/1" do
    test "retrieves participant data" do
      {:ok, pid, _session} = RoomCache.create_room("test room", :"3x3")
      user1 = user_fixture()
      send(pid, {CuberacerLive.PresenceClient, %Events.JoinRoom{user_data: %{user: user1}}})

      data = RoomServer.get_participant_data(pid)
      assert [user1.id] == Map.keys(data)
      assert ParticipantDataEntry.new(user1) == data[user1.id]

      user2 = user_fixture()
      send(pid, {CuberacerLive.PresenceClient, %Events.JoinRoom{user_data: %{user: user2}}})
      data = RoomServer.get_participant_data(pid)
      assert MapSet.new([user1.id, user2.id]) == MapSet.new(Map.keys(data))
      assert ParticipantDataEntry.new(user2) == data[user2.id]

      send(pid, {Room, %Events.TimeEntryMethodSet{user_id: user1.id, entry_method: :keyboard}})
      send(pid, {Room, %Events.Solving{user_id: user2.id}})
      data = RoomServer.get_participant_data(pid)
      assert ParticipantDataEntry.get_time_entry(data[user1.id]) == :keyboard
      assert ParticipantDataEntry.get_solving(data[user2.id])

      send(pid, {CuberacerLive.PresenceClient, %Events.LeaveRoom{user_data: %{user: user2}}})
      data = RoomServer.get_participant_data(pid)
      assert [user1.id] == Map.keys(data)
    end
  end

  describe "get_participant_count/1" do
    test "retrieves participant count" do
      {:ok, pid, _session} = RoomCache.create_room("test room", :"3x3")
      user1 = user_fixture()
      send(pid, {CuberacerLive.PresenceClient, %Events.JoinRoom{user_data: %{user: user1}}})
      assert RoomServer.get_participant_count(pid) == 1

      user2 = user_fixture()
      send(pid, {CuberacerLive.PresenceClient, %Events.JoinRoom{user_data: %{user: user2}}})
      assert RoomServer.get_participant_count(pid) == 2

      send(pid, {CuberacerLive.PresenceClient, %Events.LeaveRoom{user_data: %{user: user1}}})
      assert RoomServer.get_participant_count(pid) == 1
    end
  end

  describe "pubsub events" do
    setup do
      session = session_fixture()
      round = round_fixture()
      user = user_fixture()
      {:ok, pid} = RoomServer.start_link({session, round})
      send(pid, {CuberacerLive.PresenceClient, %Events.JoinRoom{user_data: %{user: user}}})

      %{session: session, user: user, pid: pid}
    end

    test "handles solving events", %{session: session, user: user, pid: pid} do
      participant_data = RoomServer.get_participant_data(pid)
      refute ParticipantDataEntry.get_solving(participant_data[user.id])

      Phoenix.PubSub.broadcast(
        CuberacerLive.PubSub,
        "room:#{session.id}",
        {Room, %Events.Solving{user_id: user.id}}
      )

      participant_data = RoomServer.get_participant_data(pid)
      assert ParticipantDataEntry.get_solving(participant_data[user.id])
    end

    test "handles set_time_entry events", %{session: session, user: user, pid: pid} do
      participant_data = RoomServer.get_participant_data(pid)
      assert ParticipantDataEntry.get_time_entry(participant_data[user.id]) == :timer

      Phoenix.PubSub.broadcast(
        CuberacerLive.PubSub,
        "room:#{session.id}",
        {Room, %Events.TimeEntryMethodSet{user_id: user.id, entry_method: :keyboard}}
      )

      participant_data = RoomServer.get_participant_data(pid)
      assert ParticipantDataEntry.get_time_entry(participant_data[user.id]) == :keyboard
    end
  end
end
