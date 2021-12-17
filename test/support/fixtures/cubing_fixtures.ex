defmodule CuberacerLive.CubingFixtures do
  alias CuberacerLive.Repo
  alias CuberacerLive.Cubing.Penalty

  def penalty_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{name: "OK"})

    {:ok, penalty} =
      %Penalty{}
      |> Penalty.changeset(attrs)
      |> Repo.insert()

    penalty
  end
end
