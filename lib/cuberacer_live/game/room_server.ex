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
  @inactivity_timeout :timer.minutes(1) # TODO: Update and make it so it doesn't exit if people are in the room

  defstruct [:session, messages: [], present_users: []]

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

  def get_participant_count(room_server) do
    GenServer.call(room_server, :get_participant_count)
  end

  ## Callbacks

  @impl true
  def init(%Session{} = session) do
    Logger.info("Creating room for session #{session.id}")
    subscribe_to_pubsub(session.id)
    notify_lobby_server(:room_created, session.id)

    {:ok, %__MODULE__{session: session}, @inactivity_timeout}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Terminating session #{state.session.id}, reason: #{inspect(reason)}")
    notify_lobby_server(:room_destroyed, state.session.id)
  end

  @impl true
  def handle_call(:create_round, _from, %{session: session} = state) do
    case Sessions.create_round_debounced(session) do
      {:ok, round} -> {:reply, round.scramble, state, @inactivity_timeout}
      error -> {:reply, error, state, @inactivity_timeout}
    end
  end

  def handle_call(
        {:create_solve, %User{} = user, time, penalty},
        _from,
        %{session: session} = state
      ) do
    {:ok, solve} = Sessions.create_solve(session, user, time, penalty)
    {:reply, solve, state, @inactivity_timeout}
  end

  def handle_call({:change_penalty, %User{} = user, penalty}, _from, %{session: session} = state) do
    if solve = Sessions.get_current_solve(session, user) do
      Sessions.change_penalty(solve, penalty)
    end

    {:reply, :ok, state, @inactivity_timeout}
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
    {:noreply, %{state | messages: [message | messages]}, @inactivity_timeout}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, state) do
    present_users =
      for {_user_id_str, info} <- Presence.list(pubsub_topic(state.session.id)) do
        info.user
      end

    # Let the lobby know of the change
    notify_lobby_server(:update_participant_count, %{
      session_id: state.session.id,
      participant_count: length(present_users)
    })

    {:noreply, %{state | present_users: present_users}}
  end

  def handle_info({:solving, _user_id}, state) do
    # Solving event for frontend.
    # TODO: Move this to state here so you can see "Solving..." when you join a room
    # in the middle of someone solving
    {:noreply, state}
  end

  def handle_info(:timeout, state) do
    IO.puts("got timeout")
    {:stop, :normal, state}
  end

  ## Helpers

  defp notify_lobby_server(event, result) do
    Phoenix.PubSub.broadcast!(CuberacerLive.PubSub, @lobby_server_topic, {event, result})
  end

  defp pubsub_topic(session_id) do
    "room:#{session_id}"
  end

  defp subscribe_to_pubsub(session_id) do
    topic = pubsub_topic(session_id)
    CuberacerLiveWeb.Endpoint.subscribe(topic)
  end

  def global_name(session_id) do
    {:global, {__MODULE__, session_id}}
  end
end
