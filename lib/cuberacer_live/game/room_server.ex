defmodule CuberacerLive.RoomServer do
  @moduledoc """
  GenServer which represents an active room.
  """
  use GenServer, restart: :transient

  require Logger

  alias CuberacerLive.{Sessions, Messaging}
  alias CuberacerLive.Sessions.Session
  alias CuberacerLive.Accounts.User
  alias CuberacerLiveWeb.Presence

  @lobby_server_topic inspect(CuberacerLive.LobbyServer)
  @empty_room_timeout_ms :timer.minutes(1)

  defstruct [:session, messages: [], present_users: [], timeout_ref: nil]

  ## API

  def whereis(session_id) do
    case :global.whereis_name({__MODULE__, session_id}) do
      :undefined -> nil
      pid -> pid
    end
  end

  def start_link(%Session{} = session) do
    GenServer.start_link(__MODULE__, session, name: global_name(session.id))
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

  def get_present_users(room_server) do
    GenServer.call(room_server, :get_present_users)
  end

  def get_participant_count(room_server) do
    GenServer.call(room_server, :get_participant_count)
  end

  ## Callbacks

  @impl true
  def init(%Session{} = session) do
    Logger.info("Creating room for session #{session.id}")
    subscribe_to_pubsub(session.id)
    notify_lobby_server(:room_created, session.id)
    send(self(), :set_empty_room_timeout)

    {:ok, %__MODULE__{session: session}}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Terminating session #{state.session.id}, reason: #{inspect(reason)}")
    notify_lobby_server(:room_destroyed, state.session.id)
  end

  @impl true
  def handle_call(:create_round, _from, %{session: session} = state) do
    case Sessions.create_round_debounced(session) do
      {:ok, round} -> {:reply, round.scramble, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call(
        {:create_solve, %User{} = user, time, penalty},
        _from,
        %{session: session} = state
      ) do
    {:ok, solve} = Sessions.create_solve(session, user, time, penalty)
    {:reply, solve, state}
  end

  def handle_call({:change_penalty, %User{} = user, penalty}, _from, %{session: session} = state) do
    if solve = Sessions.get_current_solve(session, user) do
      Sessions.change_penalty(solve, penalty)
    end

    {:reply, :ok, state}
  end

  def handle_call(:get_present_users, _from, state) do
    {:reply, state.present_users, state}
  end

  def handle_call(:get_participant_count, _from, state) do
    #  participant_count = length(state.present_users)
    participant_count = length(Map.keys(Presence.list(pubsub_topic(state.session.id))))
    {:reply, participant_count, state}
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
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, state) do
    present_users =
      for {_user_id_str, info} <- Presence.list(pubsub_topic(state.session.id)) do
        info.user
      end

    present_users_count = length(present_users)
    new_state = %{state | present_users: present_users}

    # Let the lobby know of the change
    notify_lobby_server(:update_participant_count, %{
      session_id: state.session.id,
      participant_count: present_users_count
    })

    if present_users_count == 0 do
      send(self(), :set_empty_room_timeout)
      {:noreply, new_state, {:continue, :tell_room_to_fetch_present_users}}
    else
      send(self(), :cancel_empty_room_timeout)
      {:noreply, new_state, {:continue, :tell_room_to_fetch_present_users}}
    end
  end

  def handle_info({:solving, _user_id}, state) do
    # Solving event for frontend.
    # TODO: Move this to state here so you can see "Solving..." when you join a room
    # in the middle of someone solving
    {:noreply, state}
  end

  def handle_info(:set_empty_room_timeout, %{timeout_ref: nil} = state) do
    {:noreply, _set_state_timeout_ref(state)}
  end

  def handle_info(:set_empty_room_timeout, %{timeout_ref: timeout_ref} = state) do
    Process.cancel_timer(timeout_ref)
    {:noreply, _set_state_timeout_ref(state)}
  end

  def handle_info(:cancel_empty_room_timeout, %{timeout_ref: timeout_ref} = state) do
    Process.cancel_timer(timeout_ref)
    {:noreply, _unset_state_timeout_ref(state)}
  end

  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_continue(:tell_room_to_fetch_present_users, state) do
    Phoenix.PubSub.broadcast!(
      CuberacerLive.PubSub,
      game_room_topic(state.session.id),
      :fetch_present_users
    )

    {:noreply, state}
  end

  ## Helpers

  defp notify_lobby_server(event, result) do
    Phoenix.PubSub.broadcast!(CuberacerLive.PubSub, @lobby_server_topic, {event, result})
  end

  defp pubsub_topic(session_id) do
    "#{inspect(__MODULE__)}:#{session_id}"
  end

  defp game_room_topic(session_id) do
    "room:#{session_id}"
  end

  defp subscribe_to_pubsub(session_id) do
    topic = pubsub_topic(session_id)
    CuberacerLiveWeb.Endpoint.subscribe(topic)
  end

  defp global_name(session_id) do
    {:global, {__MODULE__, session_id}}
  end

  defp _set_state_timeout_ref(state) do
    %{state | timeout_ref: Process.send_after(self(), :timeout, @empty_room_timeout_ms)}
  end

  defp _unset_state_timeout_ref(state) do
    %{state | timeout_ref: nil}
  end
end
