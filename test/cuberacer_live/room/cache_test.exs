defmodule CuberacerLive.CacheTest do
  use CuberacerLive.DataCase, async: false
  import CuberacerLive.CubingFixtures

  alias CuberacerLive.RoomCache

  setup do
    cube_type = cube_type_fixture()
    %{cube_type: cube_type}
  end

  test "create_room/1 starts a new room server child process", %{cube_type: cube_type} do
    count_before = DynamicSupervisor.count_children(RoomCache)

    {:ok, pid, _session} =
      RoomCache.create_room(%{name: "test session", cube_type_id: cube_type.id})

    count_after = DynamicSupervisor.count_children(RoomCache)

    assert count_after == %{
             specs: count_before.specs + 1,
             active: count_before.active + 1,
             supervisors: count_before.supervisors,
             workers: count_before.workers + 1
           }

    GenServer.stop(pid)
  end

  test "server_process/1 finds the pid of the room server", %{cube_type: cube_type} do
    {:ok, pid, session} =
      RoomCache.create_room(%{name: "test session", cube_type_id: cube_type.id})

    assert RoomCache.server_process(session.id) == pid

    GenServer.stop(pid)
  end

  test "list_active_rooms/0 gets data for active sessions", %{cube_type: cube_type} do
    {:ok, pid1, session1} =
      RoomCache.create_room(%{name: "test session 1", cube_type_id: cube_type.id})

    {:ok, pid2, session2} =
      RoomCache.create_room(%{name: "test session 2", cube_type_id: cube_type.id})

    {:ok, pid3, session3} =
      RoomCache.create_room(%{name: "test session 3", cube_type_id: cube_type.id})

    GenServer.stop(pid2)
    # Gives the registry some time to update itself
    # TODO: figure out a better way to do/test this
    :timer.sleep(50)

    assert Registry.lookup(CuberacerLive.RoomRegistry, session2.id) == []

    active_values = RoomCache.list_active_rooms()
    active_sessions = Enum.map(active_values, fn value -> value.session end)

    assert Enum.count(active_values) == 2
    assert Enum.all?(active_values, fn value -> value.participant_count == 0 end)
    assert session1 in active_sessions
    refute session2 in active_sessions
    assert session3 in active_sessions

    GenServer.stop(pid1)
    GenServer.stop(pid3)
  end
end
