defmodule CuberacerLive.Sessions.Round do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rounds" do
    field :scramble, :string

    belongs_to :session, CuberacerLive.Sessions.Session
    has_many :solves, CuberacerLive.Sessions.Solve

    timestamps()
  end

  @doc """
  Changeset for creating a round.
  """
  def create_changeset(round, attrs) do
    round
    |> cast(attrs, [:scramble, :session_id])
    |> validate_required([:scramble, :session_id])
    |> cast_assoc(:session)
  end
end
