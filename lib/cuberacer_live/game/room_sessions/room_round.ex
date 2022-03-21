defmodule CuberacerLive.RoomSessions.RoomRound do
  @moduledoc """
  In-memory representation of a round.
  """

  alias CuberacerLive.RoomSessions.RoomSolve

  defstruct [:scramble, room_solves: []]

  def new(puzzle_type) do
    scramble = Whisk.scramble(puzzle_type)
    %__MODULE__{scramble: scramble}
  end

  def add_solve(%__MODULE__{} = round, %RoomSolve{} = solve) do
    unless Enum.any?(round.room_solves, &(&1.user_id == solve.user_id)) do
      %{round | room_solves: [solve | round.room_solves]}
    else
      round
    end
  end
end
