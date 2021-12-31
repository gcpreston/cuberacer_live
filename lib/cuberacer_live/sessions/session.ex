defmodule CuberacerLive.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sessions" do
    field :name, :string
    field :host_id, :id
    field :terminated, :boolean, default: false
    belongs_to :cube_type, CuberacerLive.Cubing.CubeType

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:name, :cube_type_id, :terminated])
    |> validate_required([:name, :cube_type_id])
    |> cast_assoc(:cube_type)
  end
end
