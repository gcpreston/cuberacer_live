defmodule CuberacerLive.SessionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `CuberacerLive.Sessions` context.
  """

  import CuberacerLive.AccountsFixtures

  @doc """
  Generate a session.
  """
  def session_fixture(attrs \\ %{}) do
    {:ok, session} =
      attrs
      |> Enum.into(%{
        name: "some name",
        puzzle_type: :"3x3"
      })
      |> CuberacerLive.Sessions.create_session()

    session
  end

  @doc """
  Generate a round.
  """
  def round_fixture(attrs \\ %{}) do
    session = attrs[:session] || session_fixture()
    scramble = attrs[:scramble] || "some scramble"

    {:ok, round} = CuberacerLive.Sessions.create_round(session, scramble)

    round
  end

  @doc """
  Generate a solve.
  """
  def solve_fixture(attrs \\ %{}) do
    user = user_fixture()
    round = round_fixture()

    {:ok, solve} =
      attrs
      |> Enum.into(%{
        round_id: round.id,
        user_id: user.id,
        time: 42,
        penalty: :OK
      })
      |> CuberacerLive.Sessions.create_solve()

    solve
  end
end
