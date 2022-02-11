defmodule CuberacerLive.Repo.Migrations.AddProfileData do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :wca_id, :string
      add :birthday, :date
      add :bio, :text
      add :country, :string
    end
  end
end
