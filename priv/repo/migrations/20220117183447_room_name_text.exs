defmodule CuberacerLive.Repo.Migrations.RoomNameText do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      modify :name, :text
    end
  end
end
