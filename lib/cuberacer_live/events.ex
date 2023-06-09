defmodule CuberacerLive.Events do
  @moduledoc """
  Defines Event structs for use within the pubsub system.
  """

  defmodule SolveCreated do
    defstruct solve: nil
  end

  defmodule RoundCreated do
    defstruct round: nil
  end
end
