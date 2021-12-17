defmodule CuberacerLive.Repo.Migrations.CreateSolves do
  use Ecto.Migration

  def change do
    create table(:solves) do
      add :time, :integer
      add :user_id, references(:users, on_delete: :delete_all)
      add :penalty_id, references(:penalties, on_delete: :delete_all)
      add :round_id, references(:rounds, on_delete: :delete_all)

      timestamps()
    end

    create index(:solves, [:user_id])
    create index(:solves, [:penalty_id])
    create index(:solves, [:round_id])
  end
end
