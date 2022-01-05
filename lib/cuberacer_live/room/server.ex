defmodule CuberacerLive.RoomServer do
  @moduledoc """
  GenServer to hold the state of a room.

  A room is a session combined with a chat.
  """
  use GenServer, restart: :transient

  require Logger
  import CuberacerLive.RoomRegistry, only: [via_tuple_register: 1, via_tuple_lookup: 1]

  alias CuberacerLive.{Sessions, Messaging, Cubing}
  alias CuberacerLive.RoomCache
  alias CuberacerLive.Sessions.Session
  alias CuberacerLive.Accounts.User
  alias CuberacerLive.Cubing.Penalty

  alias CuberacerLiveWeb.Presence

  # 10 seconds
  @process_lifetime_ms 10_000

  @topic inspect(__MODULE__)

  def subscribe() do
    Phoenix.PubSub.subscribe(CuberacerLive.PubSub, @topic)
  end

  # TODO: Having :messages here but not storing rounds and solves directly seems weird...
  defstruct [:session, :timer_ref, messages: [], present_users: []]

  defp notify_subscribers(event, result) do
    Phoenix.PubSub.broadcast(CuberacerLive.PubSub, @topic, {__MODULE__, event, result})
  end

  defp presence_topic(session_id) do
    "room:#{session_id}"
  end

  defp subscribe_to_presence(session_id) do
    topic = presence_topic(session_id)
    CuberacerLiveWeb.Endpoint.subscribe(topic)
  end

  defp fetch_present_users(%{session: session} = state) do
    users =
      for {_user_id_str, info} <- Presence.list(presence_topic(session.id)) do
        info.user
      end

    RoomCache.set_participant_count(session, Enum.count(users))
    %{state | present_users: users}
  end

  ## API

  def start_link(%Session{} = session) do
    GenServer.start_link(__MODULE__, session, name: via_tuple_register(session))
  end

  def create_round(%Session{} = session) do
    GenServer.call(via_tuple_lookup(session), :create_round)
  end

  def create_solve(
        %Session{} = session,
        %User{} = user,
        time,
        %Penalty{} = penalty \\ Cubing.get_penalty("OK")
      ) do
    GenServer.cast(via_tuple_lookup(session), {:create_solve, user, time, penalty})
  end

  def change_penalty(%Session{} = session, %User{} = user, %Penalty{} = penalty) do
    GenServer.cast(via_tuple_lookup(session), {:change_penalty, user, penalty})
  end

  def send_message(%Session{} = session, %User{} = user, message) do
    GenServer.cast(via_tuple_lookup(session), {:send_message, user, message})
  end

  def set_session_name(%Session{} = session, name) do
    GenServer.cast(via_tuple_lookup(session), {:set_session_name, name})
  end

  ## Callbacks

  @impl true
  def init(%Session{} = session) do
    Logger.info("Creating room for session #{session.id}")
    send(self(), :set_terminate_timer)
    subscribe_to_presence(session.id)
    notify_subscribers(:room_created, session)

    {:ok, %__MODULE__{session: session}}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Terminating session #{state.session.id}, reason: #{reason}")
    notify_subscribers(:room_terminated, state.session)
  end

  @impl true
  def handle_call(:create_round, _from, %{session: session} = state) do
    {:ok, round} = Sessions.create_round(%{session_id: session.id})
    {:reply, round.scramble, state}
  end

  @impl true
  def handle_cast(
        {:create_solve, %User{} = user, time, penalty},
        %{session: session} = state
      ) do
    Sessions.create_solve(session, user, time, penalty)
    {:noreply, state}
  end

  def handle_cast(
        {:change_penalty, %User{} = user, %Penalty{} = penalty},
        %{session: session} = state
      ) do
    if solve = Sessions.get_current_solve(session, user) do
      Sessions.change_penalty(solve, penalty)
    end

    {:noreply, state}
  end

  def handle_cast(
        {:send_message, %User{} = user, message},
        %{session: session, messages: messages} = state
      ) do
    {:ok, message} = Messaging.create_room_message(session, user, message)
    {:noreply, %{state | messages: [message | messages]}}
  end

  def handle_cast({:set_session_name, name}, %{session: session} = state) do
    {:ok, updated_session} = Sessions.update_session(session, %{name: name})

    case RoomCache.set_session(updated_session) do
      {_new_value, _old_value} -> {:noreply, %{state | session: updated_session}}
      :error -> {:noreply, state}
    end
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, state) do
    {:noreply, state |> fetch_present_users()}
  end

  # Callback handler that sets a timer to terminate this process.
  def handle_info(:set_terminate_timer, %{timer_ref: nil} = state) do
    updated_state = %{
      state
      | timer_ref: Process.send_after(self(), {:end_process, :normal}, @process_lifetime_ms)
    }

    {:noreply, updated_state}
  end

  def handle_info(:set_terminate_timer, %{timer_ref: timer_ref} = state) do
    timer_ref |> Process.cancel_timer()

    updated_state = %{
      state
      | timer_ref: Process.send_after(self(), {:end_process, :normal}, @process_lifetime_ms)
    }

    {:noreply, updated_state}
  end

  def handle_info({:end_process, reason}, state) do
    {:stop, reason, state}
  end
end
