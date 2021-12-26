defmodule CuberacerLive.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sessions" do
    field :name, :string
    field :host_id, :id

    has_many :rounds, CuberacerLive.Sessions.Round

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
