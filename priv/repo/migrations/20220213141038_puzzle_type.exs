defmodule CuberacerLive.Repo.Migrations.PuzzleType do
  use Ecto.Migration

  def up do
    alter table(:sessions) do
      add :puzzle_type, :string

      # Enum.each(CuberacerLive.Repo.all(CuberacerLive.Sessions.Session), fn session ->
      #   session = CuberacerLive.Repo.preload(session, :cube_type)
      #   changeset = Ecto.Changeset.cast(session, %{cube_type: session.cube_type.name})
      #   Repo.update!(changeset)
      # end)
    end
  end

  def down do
    alter table(:sessions) do
      remove :puzzle_type
    end
  end
end
