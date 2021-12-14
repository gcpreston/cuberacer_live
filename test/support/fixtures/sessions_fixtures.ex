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
end
