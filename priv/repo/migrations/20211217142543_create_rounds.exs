defmodule CuberacerLive.Repo.Migrations.CreateRounds do
  use Ecto.Migration

  def change do
    create table(:rounds) do
      add :scramble, :string
      add :session_id, references(:sessions, on_delete: :delete_all)

      timestamps()
    end

    create index(:rounds, [:session_id])
  end
end
