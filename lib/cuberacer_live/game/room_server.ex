defmodule CuberacerLive.RoomServer do
  @moduledoc """
  GenServer which represents an active room.
  """
  use GenServer, restart: :transient

  require Logger

  alias CuberacerLive.Sessions
  alias CuberacerLive.Sessions.{Session, Round}
  alias CuberacerLive.ParticipantDataEntry
  alias CuberacerLive.Events
  alias CuberacerLive.Room

  defstruct [
    :session,
    participant_data: %{},
    timeout_ref: nil,
    empty_round_flag: true,
    current_round_id: nil
  ]

  ## API

  @doc """
  Gets the pid of room server.
  """
  def whereis(session_id) do
    case :global.whereis_name({__MODULE__, session_id}) do
      :undefined -> nil
      pid -> pid
    end
  end

  def global_name(session_id) do
    {:global, {__MODULE__, session_id}}
  end

  def start_link({%Session{} = session, %Round{} = round}) do
    GenServer.start_link(__MODULE__, {session, round}, name: global_name(session.id))
  end

  def create_round(room_server) do
    GenServer.call(room_server, :create_round)
  end

  def get_participant_count(room_server) do
    GenServer.call(room_server, :get_participant_count)
  end

  def get_participant_data(room_server) do
    GenServer.call(room_server, :get_participant_data)
  end

  ## Callbacks

  @impl true
  def init({%Session{} = session, %Round{id: round_id}}) do
    Logger.info("Creating room for session #{session.id}")
    subscribe_to_pubsub(session)
    notify_lobby_server(:room_created, session.id)

    {:ok, %__MODULE__{session: session, current_round_id: round_id} |> set_empty_room_timeout()}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Terminating session #{state.session.id}, reason: #{inspect(reason)}")
    notify_lobby_server(:room_destroyed, state.session.id)
  end

  @impl true
  def handle_call(:create_round, _from, %{session: session} = state) do
    if state.empty_round_flag do
      {:reply, {:error, :empty_round}, state}
    else
      result = Sessions.create_round(session)

      new_state =
        case result do
          {:ok, round} -> %{state | empty_round_flag: true, current_round_id: round.id}
          _error -> state
        end

      {:reply, result, new_state}
    end
  end

  def handle_call(:get_participant_count, _from, state) do
    participant_count = Enum.count(state.participant_data)
    {:reply, participant_count, state}
  end

  def handle_call(:get_participant_data, _from, state) do
    {:reply, state.participant_data, state}
  end

  @impl true
  def handle_info({CuberacerLive.PresenceClient, %Events.JoinRoom{user_data: user_data}}, state) do
    user = user_data.user

    new_participant_data =
      state.participant_data
      |> Map.put(user_data.user.id, ParticipantDataEntry.new(user))

    new_state = %{state | participant_data: new_participant_data}

    present_users_count = Enum.count(new_participant_data)

    # Let the lobby know of the change
    notify_lobby_server(:update_participant_count, %{
      session_id: state.session.id,
      participant_count: present_users_count
    })

    new_state =
      if present_users_count == 0 do
        new_state |> set_empty_room_timeout()
      else
        new_state |> cancel_empty_room_timeout()
      end

    {:noreply, new_state}
  end

  def handle_info({CuberacerLive.PresenceClient, %Events.LeaveRoom{user_data: user_data}}, state) do
    new_participant_data =
      Map.filter(state.participant_data, fn {user_id, _data} ->
        user_id != user_data.user.id
      end)

    new_state = %{state | participant_data: new_participant_data}

    present_users_count = Enum.count(new_participant_data)

    # Let the lobby know of the change
    notify_lobby_server(:update_participant_count, %{
      session_id: state.session.id,
      participant_count: present_users_count
    })

    new_state =
      if present_users_count == 0 do
        new_state |> set_empty_room_timeout()
      else
        new_state |> cancel_empty_room_timeout()
      end

    {:noreply, new_state}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, state) do
    {:noreply, state}
  end

  def handle_info({Room, %Events.Solving{user_id: user_id}}, state) do
    new_entry = ParticipantDataEntry.set_solving(state.participant_data[user_id], true)
    {:noreply, put_in(state.participant_data[user_id], new_entry)}
  end

  def handle_info(
        {Room, %Events.TimeEntryMethodSet{user_id: user_id, entry_method: method}},
        state
      ) do
    new_entry = ParticipantDataEntry.set_time_entry(state.participant_data[user_id], method)
    {:noreply, put_in(state.participant_data[user_id], new_entry)}
  end

  def handle_info(
        {Sessions, %Events.SolveCreated{solve: %{user_id: user_id, round_id: round_id}}},
        %{current_round_id: current_round_id} = state
      ) do
    old_entry = state.participant_data[user_id]

    new_state =
      if old_entry && round_id == current_round_id do
        new_entry = ParticipantDataEntry.set_solving(state.participant_data[user_id], false)
        %{put_in(state.participant_data[user_id], new_entry) | empty_round_flag: false}
      else
        state
      end

    {:noreply, new_state}
  end

  def handle_info({_module, _event}, state) do
    {:noreply, state}
  end

  def handle_info(:timeout, state) do
    Logger.info("Room #{state.session.id} timed out")
    {:stop, :normal, state}
  end

  ## Helpers

  defp empty_room_timeout_ms do
    Application.get_env(:cuberacer_live, :empty_room_timeout_ms)
  end

  defp notify_lobby_server(event, result) do
    send(CuberacerLive.LobbyServer, {event, result})
  end

  defp subscribe_to_pubsub(session) do
    Room.subscribe(session)
  end

  defp set_empty_room_timeout(%{timeout_ref: nil} = state) do
    _set_timeout(state)
  end

  defp set_empty_room_timeout(state) do
    _cancel_timeout(state)
    _set_timeout(state)
  end

  defp cancel_empty_room_timeout(%{timeout_ref: nil} = state) do
    state
  end

  defp cancel_empty_room_timeout(state) do
    _cancel_timeout(state)
    %{state | timeout_ref: nil}
  end

  defp _set_timeout(state) do
    Logger.info("Setting empty room timeout for room #{state.session.id}")
    %{state | timeout_ref: Process.send_after(self(), :timeout, empty_room_timeout_ms())}
  end

  defp _cancel_timeout(state) do
    Logger.info("Cancelling empty room timeout for room #{state.session.id}")
    Process.cancel_timer(state.timeout_ref)
  end
end
