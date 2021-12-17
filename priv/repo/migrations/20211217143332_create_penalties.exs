defmodule CuberacerLive.Repo.Migrations.CreatePenalties do
  use Ecto.Migration

  def change do
    create table(:penalties) do
      add :name, :string

      timestamps()
    end
  end
end
