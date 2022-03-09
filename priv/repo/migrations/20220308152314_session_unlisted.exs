defmodule CuberacerLive.Repo.Migrations.SessionUnlisted do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :unlisted, :boolean, default: false, null: false
    end
  end
end
