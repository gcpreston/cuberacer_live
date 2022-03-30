defmodule CuberacerLive.RoomSessions.RoomSession do
  @moduledoc """
  In-memory representation of a session.
  """

  alias CuberacerLive.Accounts.User

  defstruct [:uuid, :name, :puzzle_type, :unlisted?, :host_id, room_rounds: [], room_messages: []]

  def new(name, puzzle_type, unlisted?, %User{} = host) do
    %__MODULE__{
      uuid: Ecto.UUID.generate(),
      name: name,
      puzzle_type: puzzle_type,
      unlisted?: unlisted?,
      host_id: host.id
    }
  end
end
