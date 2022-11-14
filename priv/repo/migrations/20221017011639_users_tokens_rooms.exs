defmodule CuberacerLive.Repo.Migrations.UserRoomAuths do
  use Ecto.Migration

  def change do
    create table(:user_room_auths) do
      add :user_id, references(:users), null: false
      add :session_id, references(:sessions), null: false

      timestamps(updated_at: false)
    end
  end
end
