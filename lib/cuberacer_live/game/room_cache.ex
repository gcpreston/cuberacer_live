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
    |> Enum.filter(fn name -> match?({RoomServer, _id}, name) end)
    |> Enum.map(fn {RoomServer, session_id} -> session_id end)
  end

  def create_room(name, puzzle_type, _unlisted) do
    case Sessions.create_session_and_round(name, puzzle_type) do
      {:ok, session, _round} ->
        {:ok, pid} =
          DynamicSupervisor.start_child(__MODULE__, {RoomServer, session})

        {:ok, pid, session}

      err ->
        err
    end
  end

  def server_process(session_id) do
    RoomServer.whereis(session_id)
  end
end
