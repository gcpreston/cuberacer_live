defmodule CuberacerLive.LobbyServer do
  use GenServer

  alias CuberacerLive.{RoomCache, RoomServer}

  @topic inspect(__MODULE__)
  @game_lobby_topic "lobby"

  defstruct rooms: %{}

  ## API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_participant_counts do
    GenServer.call(__MODULE__, :get_participant_counts)
  end

  ## Callbacks

  @impl true
  def init(_) do
    # Get current presence counts
    rooms_state =
      for session_id <- RoomCache.list_room_ids() do
        pid = RoomServer.whereis(session_id)
        participant_count = RoomServer.get_participant_count(pid)

        {session_id, %{participant_count: participant_count}}
      end
      |> Enum.into(%{})

    # Subscribe to changes
    subscribe_to_pubsub()

    {:ok, %__MODULE__{rooms: rooms_state}}
  end

  @impl true
  def handle_info({:room_created, room_session_uuid}, state) do
    {:noreply, %{state | rooms: Map.put(state.rooms, room_session_uuid, %{participant_count: 0})},
     {:continue, :tell_game_lobby_to_fetch}}
  end

  def handle_info({:room_destroyed, room_session_uuid}, state) do
    {:noreply, %{state | rooms: Map.delete(state.rooms, room_session_uuid)},
     {:continue, :tell_game_lobby_to_fetch}}
  end

  def handle_info(
        {:update_participant_count,
         %{uuid: room_session_uuid, participant_count: participant_count}},
        state
      ) do
    # This conditional should only fail if the room process has crashed
    new_state =
      if Map.has_key?(state.rooms, room_session_uuid) do
        put_in(state.rooms[room_session_uuid].participant_count, participant_count)
      else
        state
      end

    {:noreply, new_state, {:continue, :tell_game_lobby_to_fetch}}
  end

  @impl true
  def handle_continue(:tell_game_lobby_to_fetch, state) do
    Phoenix.PubSub.broadcast!(CuberacerLive.PubSub, @game_lobby_topic, :fetch)
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_participant_counts, _from, state) do
    counts =
      Enum.reduce(state.rooms, %{}, fn {room_session_uuid, metadata}, acc ->
        Map.put(acc, room_session_uuid, metadata.participant_count)
      end)

    {:reply, counts, state}
  end

  ## Helpers

  defp subscribe_to_pubsub do
    Phoenix.PubSub.subscribe(CuberacerLive.PubSub, @topic)
  end
end
