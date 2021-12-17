defmodule CuberacerLive.Sessions.Solve do
  use Ecto.Schema
  import Ecto.Changeset

  schema "solves" do
    field :time, :integer
    belongs_to :user, CuberacerLive.Accounts.User
    belongs_to :penalty, CuberacerLive.Cubing.Penalty
    belongs_to :round, CuberacerLive.Sessions.Round

    timestamps()
  end

  @doc false
  def changeset(solve, attrs) do
    solve
    |> cast(attrs, [:time, :user_id, :penalty_id, :round_id])
    |> validate_required([:time, :user_id, :penalty_id, :round_id])
    |> cast_assoc(:user)
    |> cast_assoc(:penalty)
    |> cast_assoc(:round)
  end
end
