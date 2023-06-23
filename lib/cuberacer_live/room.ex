defmodule CuberacerLive.Room do
  @moduledoc """
  The Room context.
  """

  alias CuberacerLive.Events
  alias CuberacerLive.RoomServer
  alias CuberacerLive.{Sessions, Messaging}
  alias CuberacerLive.ParticipantDataEntry

  @type time_entry_method :: :timer | :keyboard
  @type user_id :: integer()
  @type participant_data :: %{user_id() => ParticipantDataEntry.t()}

  def subscribe(session_id) do
    Sessions.subscribe(session_id)
    Messaging.subscribe(session_id)
    Phoenix.PubSub.subscribe(CuberacerLive.PubSub, game_room_topic(session_id))
  end

  def game_room_topic(session_id) do
    "room:#{session_id}"
  end

  @spec set_time_entry(integer(), integer(), time_entry_method()) :: :ok
  def set_time_entry(session_id, user_id, entry_method) do
    Phoenix.PubSub.broadcast!(
      CuberacerLive.PubSub,
      game_room_topic(session_id),
      {__MODULE__, %Events.TimeEntryMethodSet{user_id: user_id, entry_method: entry_method}}
    )
  end

  @spec solving(integer(), integer()) :: :ok
  def solving(session_id, user_id) do
    Phoenix.PubSub.broadcast!(
      CuberacerLive.PubSub,
      game_room_topic(session_id),
      {__MODULE__, %Events.Solving{user_id: user_id}}
    )
  end

  @spec alive?(session_id()) :: boolean()
  def alive?(session_id) do
    !is_nil(RoomServer.whereis(session_id))
  end

  # TODO: Figure out what to do if pid doesn't exist

  @spec get_participant_data(session_id()) :: participant_data()
  def get_participant_data(session_id) do
    pid = RoomServer.whereis(session_id)
    RoomServer.get_participant_data(pid)
  end

  @spec get_participant_count(session_id()) :: integer()
  def get_participant_count(session_id) do
    pid = RoomServer.whereis(session_id)
    RoomServer.get_participant_count(pid)
  end

  # TODO: spec
  def create_round(session_id) do
    pid = RoomServer.whereis(session_id)
    RoomServer.create_round(pid)
  end

  # TODO: Spec
  # TODO: pass user_id? pass ecto models everywhere else?
  def create_solve(session_id, user, time, penalty) do
    pid = RoomServer.whereis(session_id)
    RoomServer.create_solve(pid, user, time, penalty)
  end

  def change_penalty(session_id, user, penalty) do
    pid = RoomServer.whereis(session_id)
    RoomServer.change_penalty(pid, user, penalty)
  end

  defdelegate send_message(session, user, message), to: Messaging, as: :create_room_message
  defdelegate list_room_messages(session), to: Messaging
  defdelegate list_rounds_of_session(session, order), to: Sessions
  defdelegate current_stats(session, user), to: Sessions
  defdelegate get_round!(round_id), to: Sessions
  defdelegate get_session(session_id), to: Sessions
end
