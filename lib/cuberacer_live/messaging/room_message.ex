defmodule CuberacerLive.Messaging.RoomMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "room_messages" do
    field :message, :string
    belongs_to :user, CuberacerLive.Accounts.User
    belongs_to :session, CuberacerLive.Sessions.Session

    timestamps()
  end

  @doc false
  def create_changeset(room_message, attrs) do
    room_message
    |> cast(attrs, [:message, :user_id, :session_id])
    |> validate_required([:message, :user_id, :session_id])
    |> cast_assoc(:user)
    |> cast_assoc(:session)
  end
end
