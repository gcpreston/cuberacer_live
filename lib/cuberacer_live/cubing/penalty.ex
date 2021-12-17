defmodule CuberacerLive.Cubing.Penalty do
  use Ecto.Schema
  import Ecto.Changeset

  schema "penalties" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(penalty, attrs) do
    penalty
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
