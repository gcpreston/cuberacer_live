defmodule CuberacerLive.RoomCache do
  @moduledoc """
  DynamicSupervisor for RoomServer processes.

  This module acts as the supervisor for RoomServers, as well as
  providing an API for registry information, such as locating
  RoomServers via RoomRegistry, and setting participant count.
  """
  alias CuberacerLive.RoomRegistry
  alias CuberacerLive.Sessions
  alias CuberacerLive.Sessions.Session

  @topic inspect(__MODULE__)

  @doc """
  Subscribe to receive updates when a RoomRegistry value changes.
  """
  def subscribe do
    Phoenix.PubSub.subscribe(CuberacerLive.PubSub, @topic)
  end

  def start_link do
    DynamicSupervisor.start_link(name: __MODULE__, strategy: :one_for_one)
  end

  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  @doc """
  Get the process of a room hosting the session with the given ID.

  If no such room exists, returns `nil`.
  """
  def server_process(session_id) do
    case Registry.lookup(RoomRegistry, session_id) do
      [{pid, _value}] -> pid
      [] -> nil
    end
  end

  @doc """
  List registry values of active rooms. This includes:
  - Session struct
  - participant count
  """
  def list_active_rooms do
    Registry.select(RoomRegistry, [
      {
        {:_, :_, :"$1"},
        [],
        [:"$1"]
      }
    ])
  end

  @doc """
  Create a room. Creates a new session for the room.

  ## Examples

      iex> create_room(attrs)
      {:ok, #PID<0.100.0>, %Session{}}

  """
  def create_room(session_attrs) do
    {:ok, session} = Sessions.create_session(session_attrs)
    session = CuberacerLive.Repo.preload(session, :cube_type)
    {:ok, pid} = start_child(session)

    {:ok, pid, session}
  end

  @doc """
  Update a :session value in the registry.

  Must be called from the room process associated with the given session.
  """
  def set_session(%Session{} = session) do
    Registry.update_value(RoomRegistry, session.id, fn value -> %{value | session: session} end)
    |> notify_subscribers(:set_session, session.id)
  end

  @doc """
  Update the :participant_count value in the registry for the given session.

  Must be called from the room process associated with the given session.
  """
  def set_participant_count(%Session{id: session_id}, participant_count) do
    Registry.update_value(RoomRegistry, session_id, fn value ->
      %{value | participant_count: participant_count}
    end)
    |> notify_subscribers(:set_participant_count, session_id)
  end

  defp notify_subscribers({_new_val, _old_val} = result, event, session_id) do
    Phoenix.PubSub.broadcast(
      CuberacerLive.PubSub,
      @topic,
      {__MODULE__, event, {session_id, result}}
    )
    result
  end

  defp notify_subscribers(:error, _event, _session_id) do
    :error
  end

  defp start_child(session) do
    DynamicSupervisor.start_child(__MODULE__, {CuberacerLive.RoomServer, session})
  end
end
