defmodule CuberacerLive.MessagingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `CuberacerLive.Messaging` context.
  """

  import CuberacerLive.SessionsFixtures
  import CuberacerLive.AccountsFixtures

  @doc """
  Generate a room_message.
  """
  def room_message_fixture(attrs \\ %{}) do
    session = attrs[:session] || session_fixture()
    user = attrs[:user] || user_fixture()
    message = attrs[:message] || "some message"

    {:ok, room_message} = CuberacerLive.Messaging.create_room_message(session, user, message)

    room_message
  end
end
