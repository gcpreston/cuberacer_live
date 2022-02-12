defmodule CuberacerLive.CubingTest do
  use CuberacerLive.DataCase, async: true
  import CuberacerLive.CubingFixtures

  alias CuberacerLive.Cubing

  test "list_cube_types/0 returns all cube types" do
    cube_type = cube_type_fixture()
    assert Cubing.list_cube_types() == [cube_type]
  end

  test "get_penalty/1 retrieves a penalty by name" do
    penalty = penalty_fixture()
    assert Cubing.get_penalty(penalty.name) == penalty
  end

  test "get_penalty/1 returns nil if no such penalty exists" do
    assert Cubing.get_penalty("invalid") == nil
  end
end
