defmodule CuberacerLive.RoomServer do
  @moduledoc """
  GenServer which represents an active room.
  """
  use GenServer, restart: :transient

  require Logger

  alias CuberacerLive.{Sessions, Messaging, Accounts}
  alias CuberacerLive.Sessions.Session
  alias CuberacerLive.Accounts.User
  alias CuberacerLive.ParticipantDataEntry

  @lobby_server_topic inspect(CuberacerLive.LobbyServer)

  defstruct [:session, participant_data: %{}, timeout_ref: nil, empty_round_flag: true]

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

  def start_link(%Session{} = session) do
    GenServer.start_link(__MODULE__, session, name: global_name(session))
  end

  def create_round(room_server) do
    GenServer.call(room_server, :create_round)
  end

  def create_solve(room_server, %User{} = user, time, penalty) do
    GenServer.call(room_server, {:create_solve, user, time, penalty})
  end

  def change_penalty(room_server, %User{} = user, penalty) do
    GenServer.call(room_server, {:change_penalty, user, penalty})
  end

  def send_message(room_server, %User{} = user, message) do
    GenServer.cast(room_server, {:send_message, user, message})
  end

  def get_participant_count(room_server) do
    GenServer.call(room_server, :get_participant_count)
  end

  def get_participant_data(room_server) do
    GenServer.call(room_server, :get_participant_data)
  end

  ## Callbacks

  @impl true
  def init(%Session{} = session) do
    Logger.info("Creating room for session #{session.id}")
    subscribe_to_pubsub(session.id)
    notify_lobby_server(:room_created, session.id)

    {:ok, %__MODULE__{session: session} |> set_empty_room_timeout()}
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
      case Sessions.create_round_debounced(session) do
        {:ok, round} -> {:reply, round.scramble, %{state | empty_round_flag: true}}
        error -> {:reply, error, state}
      end
    end
  end

  def handle_call(
        {:create_solve, %User{} = user, time, penalty},
        _from,
        %{session: session} = state
      ) do
    new_entry = ParticipantDataEntry.set_solving(state.participant_data[user.id], false)
    new_state = %{put_in(state.participant_data[user.id], new_entry) | empty_round_flag: false}
    {:ok, solve} = Sessions.create_solve(session, user, time, penalty)
    {:reply, solve, new_state}
  end

  def handle_call({:change_penalty, %User{} = user, penalty}, _from, %{session: session} = state) do
    if solve = Sessions.get_current_solve(session, user) do
      Sessions.change_penalty(solve, penalty)
    end

    {:reply, :ok, state}
  end

  def handle_call(:get_participant_count, _from, state) do
    participant_count = Enum.count(state.participant_data)
    {:reply, participant_count, state}
  end

  def handle_call(:get_participant_data, _from, state) do
    {:reply, state.participant_data, state}
  end

  @impl true
  def handle_cast(
        {:send_message, %User{} = user, message},
        %{session: session} = state
      ) do
    Messaging.create_room_message(session, user, message)
    {:noreply, state}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "presence_diff", payload: payload},
        state
      ) do
    joins_participant_data =
      Accounts.get_users(Map.keys(payload.joins))
      |> Map.new(fn user ->
        {user.id, ParticipantDataEntry.new(user)}
      end)

    leaves_user_ids =
      Enum.map(Map.keys(payload.leaves), fn id_str ->
        {user_id, ""} = Integer.parse(id_str)
        user_id
      end)

    new_participant_data =
      Map.filter(state.participant_data, fn {user_id, _data} ->
        not Enum.member?(leaves_user_ids, user_id)
      end)
      |> Map.merge(joins_participant_data)

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

    {:noreply, new_state, {:continue, {:tell_game_room_to_fetch, :participants}}}
  end

  def handle_info({:solving, user_id}, state) do
    new_entry = ParticipantDataEntry.set_solving(state.participant_data[user_id], true)
    new_state = put_in(state.participant_data[user_id], new_entry)
    {:noreply, new_state, {:continue, {:tell_game_room_to_fetch, :participant_data}}}
  end

  def handle_info({:set_time_entry, user_id, method}, state) do
    new_entry = ParticipantDataEntry.set_time_entry(state.participant_data[user_id], method)
    new_state = put_in(state.participant_data[user_id], new_entry)
    {:noreply, new_state, {:continue, {:tell_game_room_to_fetch, :participant_data}}}
  end

  def handle_info(:timeout, state) do
    Logger.info("Room #{state.session.id} timed out")
    {:stop, :normal, state}
  end

  @impl true
  def handle_continue({:tell_game_room_to_fetch, data}, state) do
    Phoenix.PubSub.broadcast!(
      CuberacerLive.PubSub,
      game_room_topic(state.session.id),
      {:fetch, data}
    )

    {:noreply, state}
  end

  ## Helpers

  defp empty_room_timeout_ms do
    Application.get_env(:cuberacer_live, :empty_room_timeout_ms)
  end

  defp notify_lobby_server(event, result) do
    Phoenix.PubSub.broadcast!(CuberacerLive.PubSub, @lobby_server_topic, {event, result})
  end

  defp game_room_topic(session_id) do
    "room:#{session_id}"
  end

  defp pubsub_topic(session_id) do
    "#{inspect(__MODULE__)}:#{session_id}"
  end

  defp subscribe_to_pubsub(session_id) do
    topic = pubsub_topic(session_id)
    CuberacerLiveWeb.Endpoint.subscribe(topic)
  end

  defp global_name(%Session{} = session) do
    {:global, {__MODULE__, session.id}}
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
