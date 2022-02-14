defmodule CuberacerLive.Repo.Migrations.PenaltyNotNull do
  use Ecto.Migration

  def up do
    rename table(:solves), :temp_penalty, to: :penalty

    alter table(:solves) do
      modify :penalty, :string, size: 10, null: false
    end
  end

  def down do
    alter table(:solves) do
      modify :penalty, :string, size: 10, null: true
    end

    rename table(:solve), :penalty, to: :temp_penalty
  end
end
