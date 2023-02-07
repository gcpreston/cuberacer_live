defmodule CuberacerLive.RoomServerTest do
  use CuberacerLive.DataCase, async: false

  alias CuberacerLive.RoomServer
  alias CuberacerLive.Messaging
  alias CuberacerLive.Messaging.RoomMessage

  import CuberacerLive.SessionsFixtures
  import CuberacerLive.AccountsFixtures

  describe "send_message" do
    setup do
      session = session_fixture()
      user = user_fixture()
      Messaging.subscribe(session.id)

      %{session: session, user: user}
    end

    test "sends a valid message", %{session: session, user: user} do
      {:ok, pid} = RoomServer.start_link(session)

      RoomServer.send_message(pid, user, "hello world!")

      assert_receive {Messaging, [:room_message, :created], %RoomMessage{message: "hello world!"}}
    end

    test "does not send an invalid message", %{session: session, user: user} do
      {:ok, pid} = RoomServer.start_link(session)

      RoomServer.send_message(pid, user, "")

      refute_receive {Messaging, [:room_message, :created], _message}
    end
  end
end
