defmodule CuberacerLive.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sessions" do
    field :name, :string
    field :host_id, :id
    field :unlisted?, :boolean, default: false, source: :unlisted

    field :puzzle_type, Ecto.Enum,
      values: [
        :"2x2",
        :"3x3",
        :"4x4",
        :"5x5",
        :"6x6",
        :"7x7",
        :Megaminx,
        :Pyraminx,
        :"Square-1",
        :Skewb,
        :Clock
      ]

    has_many :rounds, CuberacerLive.Sessions.Round
    has_many :room_messages, CuberacerLive.Messaging.RoomMessage

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:name, :puzzle_type, :unlisted?])
    |> validate_required([:name, :puzzle_type])
    |> validate_length(:name, max: 100)
  end
end
