defmodule CuberacerLive.Room do
  @moduledoc """
  A context for functions pretaining to a game room. A room is a currently
  active session, along with the extra data associated with it (messages, and
  transient state such as current participants and whether a participant
  is solving).

  This module combines relevant operations from Sessions and Messaging
  contexts which are needed for a game room. Broadcasted events are labelled
  with their context of origin, which is either Sessions, Messaging, or Room.
  """

  alias CuberacerLive.Events
  alias CuberacerLive.RoomServer
  alias CuberacerLive.{Sessions, Messaging}
  alias CuberacerLive.Sessions.Session
  alias CuberacerLive.Accounts.User
  alias CuberacerLive.ParticipantDataEntry
  alias CuberacerLive.Presence

  @type time_entry_method :: :timer | :keyboard
  @type user_id :: integer()
  @type participant_data :: %{user_id() => ParticipantDataEntry.t()}

  def subscribe(%Session{id: session_id}) do
    Sessions.subscribe(session_id)
    Messaging.subscribe(session_id)
    Phoenix.PubSub.subscribe(CuberacerLive.PubSub, game_room_topic(session_id))
  end

  def track_presence(pid, %Session{id: session_id}, %User{id: user_id}) do
    Presence.track(pid, game_room_topic(session_id), user_id, %{})
  end

  @spec set_time_entry(Session.t(), User.t(), time_entry_method()) :: :ok
  def set_time_entry(%Session{id: session_id}, %User{id: user_id}, entry_method) do
    Phoenix.PubSub.broadcast!(
      CuberacerLive.PubSub,
      game_room_topic(session_id),
      {__MODULE__, %Events.TimeEntryMethodSet{user_id: user_id, entry_method: entry_method}}
    )
  end

  @spec solving(Session.t(), User.t()) :: :ok
  def solving(%Session{id: session_id}, %User{id: user_id}) do
    Phoenix.PubSub.broadcast!(
      CuberacerLive.PubSub,
      game_room_topic(session_id),
      {__MODULE__, %Events.Solving{user_id: user_id}}
    )
  end

  @spec alive?(Session.t()) :: boolean()
  def alive?(%Session{id: session_id}) do
    !is_nil(RoomServer.whereis(session_id))
  end

  @spec get_participant_data(Session.t()) :: participant_data()
  def get_participant_data(%Session{id: session_id}) do
    name = RoomServer.global_name(session_id)
    RoomServer.get_participant_data(name)
  end

  @spec get_participant_count(Session.t()) :: integer()
  def get_participant_count(%Session{id: session_id}) do
    name = RoomServer.global_name(session_id)
    RoomServer.get_participant_count(name)
  end

  def create_round(%Session{id: session_id}) do
    name = RoomServer.global_name(session_id)
    RoomServer.create_round(name)
  end

  def change_penalty(%Session{} = session, %User{} = user, penalty) do
    if solve = Sessions.get_current_solve(session, user) do
      Sessions.change_penalty(solve, penalty)
    else
      {:error, :no_solve}
    end
  end

  defdelegate send_message(session, user, message), to: Messaging, as: :create_room_message
  defdelegate list_room_messages(session), to: Messaging
  defdelegate list_rounds_of_session(session, order), to: Sessions
  defdelegate current_stats(session, user), to: Sessions
  defdelegate get_round!(round_id), to: Sessions
  defdelegate get_session(session_id), to: Sessions
  defdelegate create_solve(session, user, time, penalty), to: Sessions

  defp game_room_topic(session_id) do
    "room:#{session_id}"
  end
end
