defmodule CuberacerLive.RoomSessions do
  @moduledoc """
  Context for in-memory sessions.
  """

  # TODO: Add round debouncing (maybe within room server)
  # TODO: Add notifications (also within room server lol)
  # TODO: Add persist! (actually within here)

  alias CuberacerLive.RoomSessions.{RoomSession, RoomRound, RoomSolve}
  alias CuberacerLive.Accounts.User

  defdelegate new_session(name, puzzle_type, unlisted?, host), to: RoomSession, as: :new
  defdelegate new_round(puzzle_type), to: RoomRound, as: :new
  defdelegate new_solve(user_id, time, penalty), to: RoomSolve, as: :new

  def new_session_and_round(name, puzzle_type, unlisted?, %User{} = host) do
    new_session(name, puzzle_type, unlisted?, host)
    |> add_round()
  end

  def add_round(%RoomSession{} = session, scramble \\ nil) do
    round =
      if scramble do
        scramble
      else
        session.puzzle_type
      end
      |> RoomRound.new()
    %{session | room_rounds: [round | session.room_rounds]}
  end

  def add_solve(%RoomSession{} = session, %RoomSolve{} = solve) do
    [current | rest] = session.room_rounds
    %{session | room_rounds: [RoomRound.add_solve(current, solve) | rest]}
  end

  def change_penalty(%RoomSession{} = session, %User{} = user, penalty) do
    [current | rest] = session.room_rounds

    current_solves =
      Enum.map(current.room_solves, fn solve ->
        if solve.user_id == user.id do
          RoomSolve.change_penalty(solve, penalty)
        else
          solve
        end
      end)

    current = %{current | room_solves: current_solves}

    %{session | room_rounds: [current | rest]}
  end
end
