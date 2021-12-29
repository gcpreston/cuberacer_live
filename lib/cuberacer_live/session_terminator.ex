defmodule CuberacerLive.SessionTerminator do
  @moduledoc """
  Process to schedule and re-schedule terminaton of sessions after inactivity.
  """
  use GenServer

  require Logger
  alias CuberacerLive.Sessions
  alias CuberacerLive.Sessions.Session

  @inactive_session_lifetime_ms 10_000 # 10 seconds

  defstruct refs: %{}

  ## API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def schedule_termination(%Session{} = session) do
    GenServer.cast(self(), {:schedule_termination, session})
  end

  ## Callbacks

  def init(_) do
    {:ok, %__MODULE__{}}
  end

  def handle_cast({:schedule_termination, %Session{} = session}, state) do
    if ref = state[session.id] do
      Process.cancel_timer(ref)
    end
    ref = Process.send_after(self(), {:terminate, session}, @inactive_session_lifetime_ms)
    {:noreply, %{state | refs: Map.put(state.refs, session.id, ref)}}
  end

  def handle_info({:terminate, %Session{} = session}, state) do
    Sessions.terminate_session(session)
    {:noreply, state}
  end
end
