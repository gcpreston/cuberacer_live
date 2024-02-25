defmodule CuberacerLive.Sessions.Solve do
  use Ecto.Schema
  import Ecto.Changeset

  schema "solves" do
    field :time, :integer
    field :penalty, Ecto.Enum, values: [:OK, :"+2", :DNF]

    belongs_to :user, CuberacerLive.Accounts.User
    belongs_to :round, CuberacerLive.Sessions.Round

    has_one :session, through: [:round, :session]

    timestamps()
  end

  def data() do
    Dataloader.Ecto.new(CuberacerLive.Repo, query: &query/2)
  end

  def query(queryable, _params) do
    queryable
  end

  @doc """
  Changeset for creating a solve.
  """
  def create_changeset(solve, attrs) do
    solve
    |> cast(attrs, [:time, :penalty, :user_id, :round_id])
    |> validate_required([:time, :penalty, :user_id, :round_id])
    |> unique_constraint(:user_id_round_id,
      message: "user has already submitted a time for this round"
    )
    |> cast_assoc(:user)
    |> cast_assoc(:round)
  end

  @doc """
  Changeset for updating the penalty on a solve.
  """
  def penalty_changeset(solve, attrs) do
    solve
    |> cast(attrs, [:penalty])
    |> validate_required([:penalty])
  end
end
