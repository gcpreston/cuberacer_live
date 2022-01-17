defmodule CuberacerLive.StatsTest do
  use ExUnit.Case

  alias CuberacerLive.Stats

  describe "avg_n/2" do
    test "calculates the average n - 2 of n" do
      assert Stats.avg_n([147, 8887, 3306, 1285, 2864], 5) == (3306 + 1285 + 2864) / 3
      assert Stats.avg_n([4140, 9659, 1731, 9407, 9826, 6430, 1901, 9294, 982, 1410, 7438, 2804], 12) == 5421.4
    end

    test "works with DNF" do
      assert Stats.avg_n([147, 8887, 3306, 1285, :dnf], 5) == (8887 + 3306 + 1285) / 3
      assert Stats.avg_n([147, 8887, 3306, :dnf, :dnf], 5) == :dnf
    end
  end
end
