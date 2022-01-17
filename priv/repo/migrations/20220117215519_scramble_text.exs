defmodule CuberacerLive.Repo.Migrations.ScrambleText do
  use Ecto.Migration

  def change do
    alter table(:rounds) do
      modify :scramble, :text
    end
  end
end
