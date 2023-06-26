defmodule CuberacerLive.RoomCache do
  alias CuberacerLive.{RoomServer, Sessions}

  require Logger

  def start_link() do
    DynamicSupervisor.start_link(name: __MODULE__, strategy: :one_for_one)
  end

  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def list_room_ids do
    :global.registered_names()
    |> Enum.filter(fn name -> match?({RoomServer, room_id} when is_integer(room_id), name) end)
    |> Enum.map(fn {RoomServer, room_id} -> room_id end)
  end

  def create_room(name, puzzle_type, password \\ nil, host \\ nil) do
    case Sessions.create_session_and_round(name, puzzle_type, password, host) do
      {:ok, session, round} ->
        {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, {RoomServer, {session, round}})
        {:ok, pid, session}

      err ->
        err
    end
  end
end
