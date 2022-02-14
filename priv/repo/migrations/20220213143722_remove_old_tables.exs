defmodule CuberacerLive.Repo.Migrations.RemoveOldTables do
  use Ecto.Migration

  def change do
    alter table(:solves) do
      remove :penalty_id
    end

    alter table(:sessions) do
      remove :cube_type_id
    end

    drop table(:penalties)

    drop table(:cube_types)
  end
end
