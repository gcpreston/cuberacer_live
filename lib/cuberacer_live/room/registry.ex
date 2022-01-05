defmodule CuberacerLive.RoomRegistry do
  @moduledoc """
  Registry for RoomServer processes.
  """
  alias CuberacerLive.Sessions.Session

  defmodule Value do
    defstruct [:session, participant_count: 0]
  end

  def start_link do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def via_tuple_register(%Session{} = session) do
    {:via, Registry,
     {__MODULE__, session.id,
      %__MODULE__.Value{session: CuberacerLive.Repo.preload(session, :cube_type)}}}
  end

  def via_tuple_lookup(%Session{id: session_id}) do
    {:via, Registry, {__MODULE__, session_id}}
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end
end
