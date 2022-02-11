defmodule CuberacerLive.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sessions" do
    field :name, :string
    field :host_id, :id

    belongs_to :cube_type, CuberacerLive.Cubing.CubeType
    has_many :rounds, CuberacerLive.Sessions.Round

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:name, :cube_type_id])
    |> validate_required([:name, :cube_type_id])
    |> validate_length(:name, max: 100)
    |> cast_assoc(:cube_type)
  end
end
