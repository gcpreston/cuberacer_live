defmodule CuberacerLive.Repo.Migrations.CreateRoomMessages do
  use Ecto.Migration

  def change do
    create table(:room_messages) do
      add :message, :text
      add :user_id, references(:users, on_delete: :nothing)
      add :session_id, references(:sessions, on_delete: :nothing)

      timestamps()
    end

    create index(:room_messages, [:session_id])
  end
end
