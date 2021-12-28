defmodule CuberacerLive.MessagingTest do
  use CuberacerLive.DataCase

  alias CuberacerLive.Messaging

  describe "room_messages" do
    alias CuberacerLive.Messaging.RoomMessage

    import CuberacerLive.SessionsFixtures
    import CuberacerLive.AccountsFixtures
    import CuberacerLive.MessagingFixtures

    test "list_room_messages/1 returns all messages for a room" do
      session1 = session_fixture()
      session2 = session_fixture()
      room_message1 = room_message_fixture(session: session1)
      room_message2 = room_message_fixture(session: session1)
      room_message3 = room_message_fixture(session: session2)

      assert Messaging.list_room_messages(session1) == [room_message1, room_message2]
      assert Messaging.list_room_messages(session2) == [room_message3]
    end

    test "get_room_message!/1 returns the room_message with given id" do
      room_message = room_message_fixture()
      assert Messaging.get_room_message!(room_message.id) == room_message
    end

    test "create_room_message/3 with valid data creates a room_message" do
      session = session_fixture()
      user = user_fixture()
      message = "some message"

      assert {:ok, %RoomMessage{} = room_message} =  Messaging.create_room_message(session, user, message)
      assert room_message.session_id == session.id
      assert room_message.user_id == user.id
      assert room_message.message == message
    end

    test "create_room_message/3 with no message returns error changeset" do
      session = session_fixture()
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Messaging.create_room_message(session, user, nil)
    end
  end
end
