defmodule CuberacerLive.RoomServerTest do
  use CuberacerLive.DataCase, async: false

  alias CuberacerLive.ParticipantDataEntry
  alias CuberacerLive.{Events, RoomServer, Sessions, Messaging, Room}
  alias CuberacerLive.Messaging.RoomMessage
  alias CuberacerLive.Sessions.Solve

  import CuberacerLive.SessionsFixtures
  import CuberacerLive.AccountsFixtures

  describe "send_message" do
    setup do
      session = session_fixture()
      user = user_fixture()
      Messaging.subscribe(session.id)
      {:ok, pid} = RoomServer.start_link(session)

      %{user: user, pid: pid}
    end

    test "sends a valid message", %{user: user, pid: pid} do
      RoomServer.send_message(pid, user, "hello world!")

      assert_receive {Messaging,
                      %Events.RoomMessageCreated{
                        room_message: %RoomMessage{message: "hello world!"}
                      }}
    end

    test "does not send an invalid message", %{user: user, pid: pid} do
      RoomServer.send_message(pid, user, "")

      refute_receive {Messaging, %Events.RoomMessageCreated{room_message: _message}}
    end
  end

  describe "create_round" do
    setup do
      {:ok, session, _round} = Sessions.create_session_and_round("test", :"3x3")
      {:ok, pid} = RoomServer.start_link(session)

      %{pid: pid}
    end

    test "does not allow creation of new round at start", %{pid: pid} do
      assert {:error, :empty_round} = RoomServer.create_round(pid)
    end

    test "allows creation of new round after a solve is submitted", %{pid: pid} do
      user = user_fixture()

      send(pid, {CuberacerLive.PresenceClient, %Events.JoinRoom{user_data: %{user: user}}})

      assert %Solve{} = RoomServer.create_solve(pid, user, 15341, :OK)
      assert is_binary(RoomServer.create_round(pid))
      assert {:error, :empty_round} = RoomServer.create_round(pid)
    end
  end

  describe "pubsub events" do
    setup do
      session = session_fixture()
      user = user_fixture()
      {:ok, pid} = RoomServer.start_link(session)
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
