defmodule CuberacerLive.Cubing.CubeType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cube_types" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(cube_type, attrs) do
    cube_type
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
