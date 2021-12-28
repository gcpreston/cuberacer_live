defmodule CuberacerLive.Repo.Migrations.SessionCubeType do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :cube_type_id, references(:cube_types), null: false
    end

    create index(:sessions, [:cube_type_id])
  end
end
