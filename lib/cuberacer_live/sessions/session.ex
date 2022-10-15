defmodule CuberacerLive.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sessions" do
    field :name, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true

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

    belongs_to :host, CuberacerLive.Accounts.User
    has_many :rounds, CuberacerLive.Sessions.Round
    has_many :room_messages, CuberacerLive.Messaging.RoomMessage

    timestamps()
  end

  @doc """
  Changeset for creating a session.
  """
  def create_changeset(session, attrs) do
    session
    |> cast(attrs, [:host_id, :name, :puzzle_type, :password])
    |> validate_required([:host_id, :name, :puzzle_type])
    |> validate_length(:name, max: 100)
    |> maybe_hash_password()
  end

  defp maybe_hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Generic changeset for sessions. Does not allow the password to be changed.
  """
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:host_id, :name, :puzzle_type])
    |> validate_required([:name, :puzzle_type])
    |> validate_length(:name, max: 100)
  end
end
