defmodule CuberacerLive.Accounts.UserRoomAuth do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_room_auths" do
    belongs_to :user, CuberacerLive.Accounts.User
    belongs_to :session, CuberacerLive.Sessions.Session

    timestamps(updated_at: false)
  end

  def create_changeset(user_token_room, attrs) do
    user_token_room
    |> cast(attrs, [:user_id, :session_id])
    |> validate_required([:user_id, :session_id])
  end
end
