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

  defmodule TimeEntryMethodSet do
    defstruct user_id: nil, entry_method: nil
  end

  defmodule Solving do
    defstruct user_id: nil
  end

  defmodule JoinRoom do
    defstruct user_data: nil
  end

  defmodule LeaveRoom do
    defstruct user_data: nil
  end
end
