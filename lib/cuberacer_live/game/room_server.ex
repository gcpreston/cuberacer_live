defmodule CuberacerLive.RoomServer do
  @moduledoc """
  GenServer which represents an active room.
  """
  use GenServer, restart: :transient

  require Logger

  alias CuberacerLive.{RoomSessions, Messaging, Accounts}
  alias CuberacerLive.RoomSessions.RoomSession
  alias CuberacerLive.Accounts.User

  @lobby_server_topic inspect(CuberacerLive.LobbyServer)

  defstruct [:session, messages: [], participant_data: %{}, timeout_ref: nil]

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

  def start_link(%RoomSession{} = session) do
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
  def init(%RoomSession{} = session) do
    Logger.info("Creating room for session #{session.uuid}")
    subscribe_to_pubsub(session.uuid)
    notify_lobby_server(:room_created, session.uuid)

    {:ok, %__MODULE__{session: session} |> set_empty_room_timeout()}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Terminating session #{state.session.uuid}, reason: #{inspect(reason)}")
    notify_lobby_server(:room_destroyed, state.session.uuid)
  end

  @impl true
  def handle_call(:create_round, _from, %{session: session} = state) do
    new_session = RoomSessions.add_round(session)
    %{state | session: new_session}
  end

  def handle_call(
        {:create_solve, %User{} = user, time, penalty},
        _from,
        %{session: session} = state
      ) do
    new_state = put_in(state.participant_data[user.id].meta.solving, false)
    solve = RoomSessions.new_solve(user, time, penalty)
    new_session = RoomSessions.add_solve(session, solve)
    {:reply, solve, %{new_state | session: new_session}}
  end

  def handle_call({:change_penalty, %User{} = user, penalty}, _from, %{session: session} = state) do
    new_session = RoomSessions.change_penalty(session, user, penalty)
    {:reply, :ok, %{state | session: new_session}}
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
        %{session: session, messages: messages} = state
      ) do
    {:ok, message} = Messaging.create_room_message(session, user, message)
    {:noreply, %{state | messages: [message | messages]}}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "presence_diff", payload: payload},
        state
      ) do
    joins_participant_data =
      Accounts.get_users(Map.keys(payload.joins))
      |> Map.new(fn user ->
        {user.id, participant_data_entry(user)}
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
      uuid: state.session.uuid,
      participant_count: present_users_count
    })

    if present_users_count == 0 do
      {:noreply, new_state |> set_empty_room_timeout(),
       {:continue, {:tell_game_room_to_fetch, :participants}}}
    else
      {:noreply, new_state |> cancel_empty_room_timeout(),
       {:continue, {:tell_game_room_to_fetch, :participants}}}
    end
  end

  def handle_info({:solving, user_id}, state) do
    {:noreply, put_in(state.participant_data[user_id].meta.solving, true),
     {:continue, {:tell_game_room_to_fetch, :participant_data}}}
  end

  def handle_info({:set_time_entry, user_id, method}, state) do
    {:noreply, put_in(state.participant_data[user_id].meta.time_entry, method),
     {:continue, {:tell_game_room_to_fetch, :participant_data}}}
  end

  def handle_info(:timeout, state) do
    Logger.info("Room #{state.session.uuid} timed out")
    {:stop, :normal, state}
  end

  @impl true
  def handle_continue({:tell_game_room_to_fetch, data}, state) do
    Phoenix.PubSub.broadcast!(
      CuberacerLive.PubSub,
      game_room_topic(state.session.uuid),
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

  defp global_name(%RoomSession{} = session) do
    {:global, {__MODULE__, session.uuid}}
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
    Logger.info("Setting empty room timeout for room #{state.session.uuid}")
    %{state | timeout_ref: Process.send_after(self(), :timeout, empty_room_timeout_ms())}
  end

  defp _cancel_timeout(state) do
    Logger.info("Cancelling empty room timeout for room #{state.session.uuid}")
    Process.cancel_timer(state.timeout_ref)
  end

  defp participant_data_entry(user) do
    %{user: user, meta: %{solving: false, time_entry: :timer}}
  end
end
