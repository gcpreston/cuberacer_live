defmodule CuberacerLive.Repo.Migrations.PenaltyColumn do
  use Ecto.Migration

  def up do
    alter table(:solves) do
      add :temp_penalty, :string, size: 10

      Enum.each(CuberacerLive.Repo.all(CuberacerLive.Sessions.Solves), fn solve ->
        solve = CuberacerLive.Repo.preload(solve, :penalty)
        changeset = Ecto.Changeset.cast(solve, %{temp_penalty: solve.penalty.name})
        Repo.update!(changeset)
      end)
    end
  end

  def down do
    alter table(:solves) do
      remove :temp_penalty
    end
  end
end
