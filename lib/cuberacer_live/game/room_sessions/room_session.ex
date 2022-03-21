defmodule CuberacerLive.RoomSessions.RoomSession do
  @moduledoc """
  In-memory representation of a session.
  """

  defstruct [:name, :puzzle_type, :unlisted?, :host_id, room_rounds: [], room_messages: []]

  def new(name, puzzle_type, unlisted?, host_id) do
    %__MODULE__{name: name, puzzle_type: puzzle_type, unlisted?: unlisted?, host_id: host_id}
  end
end
