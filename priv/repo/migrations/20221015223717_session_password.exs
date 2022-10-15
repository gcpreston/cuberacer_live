defmodule CuberacerLive.Repo.Migrations.SessionPassword do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :hashed_password, :string
      remove :unlisted
    end
  end
end
