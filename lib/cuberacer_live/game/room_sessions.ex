defmodule CuberacerLive.RoomSessions do
  @moduledoc """
  Context for in-memory sessions.
  """

  alias CuberacerLive.RoomSessions.{RoomSession, RoomRound, RoomSolve}

  defdelegate new_session(name, puzzle_type, unlisted?, host_id), to: RoomSession, as: :new
  defdelegate new_round(puzzle_type), to: RoomRound, as: :new
  defdelegate new_solve(user_id, time, penalty), to: RoomSolve, as: :new

  def add_round(%RoomSession{} = session) do
    room_round = RoomRound.new(session.puzzle_type)
    %{session | room_rounds: [room_round | session.room_rounds]}
  end

  def add_solve(%RoomSession{} = session, %RoomSolve{} = solve) do
    [current | rest] = session.room_rounds
    %{session | room_rounds: [RoomRound.add_solve(current, solve) | rest]}
  end

  def change_penalty(%RoomSession{} = session, user_id: user_id, penalty: penalty) do
    [current | rest] = session.room_rounds

    current_solves =
      Enum.map(current.room_solves, fn solve ->
        if solve.user_id == user_id do
          RoomSolve.change_penalty(solve, penalty)
        else
          solve
        end
      end)

    current = %{current | room_solves: current_solves}

    %{session | room_rounds: [current | rest]}
  end
end
