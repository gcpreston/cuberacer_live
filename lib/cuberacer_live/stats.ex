defmodule CuberacerLive.Stats do
  @moduledoc """
  Functions for cubing statistics. Deals with times in milliseconds,
  and `:dnf` to represent DNF times.
  """

  @doc """
  Calculate the average of N for the given times.

  If more than `n` times are given, calculates the average for the first `n`.
  """
  def avg_n(times, n) when length(times) >= n do
    Enum.take(times, n)
    |> do_middle_avg()
  end

  def avg_n(_times, _n) do
    :dnf
  end

  defp do_middle_avg(times) do
    # In Elixir, atom > integer, so :dnf is counted as max over any number
    {min, max} = Enum.min_max(times)
    middles = times -- [min, max]

    if :dnf in middles do
      :dnf
    else
      do_avg(middles)
    end
  end

  defp do_avg(list) do
    Enum.sum(list) / length(list)
  end
end
