defmodule CuberacerLive.Repo.Migrations.UserRoundUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:solves, [:user_id, :round_id])
  end
end
