defmodule CuberacerLive.RoomCache do
  alias CuberacerLive.{RoomServer, RoomSessions}
  alias CuberacerLive.Accounts.User

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

  def create_room(name, puzzle_type, unlisted?, %User{} = host) do
    session = RoomSessions.new_session_and_round(name, puzzle_type, unlisted?, host)
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, {RoomServer, session})

    {:ok, pid, session}
  end
end
