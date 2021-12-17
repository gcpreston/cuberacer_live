# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     CuberacerLive.Repo.insert!(%CuberacerLive.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias CuberacerLive.Repo
alias CuberacerLive.Cubing.Penalty
alias CuberacerLive.Cubing.CubeType

if not Repo.exists?(Penalty) do
  Repo.insert!(%Penalty{} |> Penalty.changeset(%{name: "OK"}))
  Repo.insert!(%Penalty{} |> Penalty.changeset(%{name: "+2"}))
  Repo.insert!(%Penalty{} |> Penalty.changeset(%{name: "DNF"}))
end

if not Repo.exists?(CubeType) do
  Repo.insert!(%CubeType{} |> CubeType.changeset(%{name: "2x2"}))
  Repo.insert!(%CubeType{} |> CubeType.changeset(%{name: "3x3"}))
  Repo.insert!(%CubeType{} |> CubeType.changeset(%{name: "4x4"}))
  Repo.insert!(%CubeType{} |> CubeType.changeset(%{name: "5x5"}))
  Repo.insert!(%CubeType{} |> CubeType.changeset(%{name: "6x6"}))
  Repo.insert!(%CubeType{} |> CubeType.changeset(%{name: "7x7"}))
  Repo.insert!(%CubeType{} |> CubeType.changeset(%{name: "Megaminx"}))
  Repo.insert!(%CubeType{} |> CubeType.changeset(%{name: "Pyraminx"}))
  Repo.insert!(%CubeType{} |> CubeType.changeset(%{name: "Square-1"}))
  Repo.insert!(%CubeType{} |> CubeType.changeset(%{name: "Skewb"}))
  Repo.insert!(%CubeType{} |> CubeType.changeset(%{name: "Clock"}))
end
