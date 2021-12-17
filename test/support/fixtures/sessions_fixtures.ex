defmodule CuberacerLive.SessionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `CuberacerLive.Sessions` context.
  """

  @doc """
  Generate a session.
  """
  def session_fixture(attrs \\ %{}) do
    {:ok, session} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> CuberacerLive.Sessions.create_session()

    session
  end

  @doc """
  Generate a round.
  """
  def round_fixture(attrs \\ %{}) do
    session = session_fixture()

    {:ok, round} =
      attrs
      |> Enum.into(%{
        scramble: "some scramble",
        session_id: session.id
      })
      |> CuberacerLive.Sessions.create_round()

    round
  end

  @doc """
  Generate a solve.
  """
  def solve_fixture(attrs \\ %{}) do
    user = CuberacerLive.AccountsFixtures.user_fixture()
    penalty = %{id: 1} # TODO: Penalty fixture
    round = round_fixture()

    {:ok, solve} =
      attrs
      |> Enum.into(%{
        time: 42,
        user_id: user.id,
        penalty_id: penalty.id,
        round_id: round.id
      })
      |> CuberacerLive.Sessions.create_solve()

    solve
  end
end
