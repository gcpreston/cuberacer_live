defmodule CuberacerLive.RoomSessions.RoomSolve do
  @moduledoc """
  In-memory representation of a solve.
  """

  defstruct [:user_id, :time, :penalty]

  def new(user_id, time, penalty) do
    %__MODULE__{user_id: user_id, time: time, penalty: penalty}
  end

  def change_penalty(%__MODULE__{} = solve, penalty) do
    %{solve | penalty: penalty}
  end
end
