defmodule CuberacerLive.SessionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `CuberacerLive.Sessions` context.
  """

  import CuberacerLive.AccountsFixtures
  import CuberacerLive.CubingFixtures

  @doc """
  Generate a session.
  """
  def session_fixture(attrs \\ %{}) do
    cube_type = cube_type_fixture()

    {:ok, session} =
      attrs
      |> Enum.into(%{
        name: "some name",
        cube_type_id: cube_type.id
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
    user = user_fixture()
    penalty = CuberacerLive.Cubing.get_penalty("OK") || penalty_fixture()
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
