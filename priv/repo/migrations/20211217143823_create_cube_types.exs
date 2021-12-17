defmodule CuberacerLive.Repo.Migrations.CreateCubeTypes do
  use Ecto.Migration

  def change do
    create table(:cube_types) do
      add :name, :string

      timestamps()
    end
  end
end
