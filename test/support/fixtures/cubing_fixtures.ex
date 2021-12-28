defmodule CuberacerLive.CubingFixtures do
  alias CuberacerLive.Repo
  alias CuberacerLive.Cubing.{Penalty, CubeType}

  def penalty_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{name: "OK"})

    {:ok, penalty} =
      %Penalty{}
      |> Penalty.changeset(attrs)
      |> Repo.insert()

    penalty
  end

  def cube_type_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{name: "3x3"})

    {:ok, cube_type} =
      %CubeType{}
      |> CubeType.changeset(attrs)
      |> Repo.insert()

    cube_type
  end
end
