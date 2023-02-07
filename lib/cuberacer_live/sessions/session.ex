defmodule CuberacerLive.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sessions" do
    field :name, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true

    field :puzzle_type, Ecto.Enum, values: Whisk.puzzle_types()

    belongs_to :host, CuberacerLive.Accounts.User
    has_many :rounds, CuberacerLive.Sessions.Round
    has_many :room_messages, CuberacerLive.Messaging.RoomMessage
    has_many :user_room_auths, CuberacerLive.Accounts.UserRoomAuth

    timestamps()
  end

  @doc """
  Changeset for creating a session.
  """
  def create_changeset(session, attrs) do
    session
    |> cast(attrs, [:host_id, :name, :puzzle_type, :password])
    |> validate_required([:name, :puzzle_type])
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
    |> cast(attrs, [:host_id, :name, :puzzle_type, :password])
    |> validate_required([:name, :puzzle_type])
    |> validate_length(:name, max: 100)
  end

  @doc """
  Verifies the session password.

  If there is no session or the session doesn't have a password, we call
  `Argon2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%CuberacerLive.Sessions.Session{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Argon2.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      changeset |> add_error(:password, "is not valid")
    end
  end
end
