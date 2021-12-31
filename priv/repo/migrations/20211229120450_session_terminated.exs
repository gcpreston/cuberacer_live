defmodule CuberacerLive.Repo.Migrations.SessionTerminated do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :terminated, :boolean, default: false, null: false
    end
  end
end
