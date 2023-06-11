defmodule CuberacerLive.Events do
  @moduledoc """
  Defines Event structs for use within the pubsub system.
  """

  defmodule SolveCreated do
    defstruct solve: nil
  end

  defmodule SolveUpdated do
    defstruct solve: nil
  end

  defmodule RoundCreated do
    defstruct round: nil
  end

  defmodule RoomMessageCreated do
    defstruct room_message: nil
  end

  defmodule SessionCreated do
    defstruct session: nil
  end

  defmodule SessionUpdated do
    defstruct session: nil
  end

  defmodule SessionDeleted do
    defstruct session: nil
  end
end