defmodule CuberacerLive.Sessions.Round do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rounds" do
    field :scramble, :string
    belongs_to :session, CuberacerLive.Sessions.Session

    timestamps()
  end

  @doc false
  def changeset(round, attrs) do
    round
    |> cast(attrs, [:scramble, :session_id])
    |> validate_required([:scramble, :session_id])
    |> cast_assoc(:session)
  end
end
