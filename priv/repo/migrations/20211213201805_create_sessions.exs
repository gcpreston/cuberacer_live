defmodule CuberacerLive.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add :name, :string
      add :host_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:sessions, [:host_id])
  end
end
