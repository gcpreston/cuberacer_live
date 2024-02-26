defmodule CuberacerLive.Events do
  @moduledoc """
  Defines Event structs for use within the pubsub system.
  """

  # What am i doing
  # - 3 concepts: event, topic, payload
  # - event: atom in absinthe, ??? in elixir (module name rn)
  # - topic: string in both
  # - payload: absinthe object identified (atom), ??? in elixir (struct rn)

  # How do I want it to work to define and use events?
  # -

  # Other notes
  # - Absinthe separates object definitions by context more or less,
  #   but keeps a unified overall schema
  # - What would that look like here? Maybe events are defined close to
  #   their own context, but the data i'm figuring out an implementation
  #   for could live in a more common area?
  #
  # - Something like notify_subscribers has to be called from multiple contexts.
  # - IDEA: Make common function here, implement polymorphic data extraction
  #   in whatever way makes sense, call min logic from each place
  #
  # In context:
  # - Pass event identifier and result value to a worker function
  # In worker function:
  # - Get absinthe field, internal event identifier (maybe can just be the
  #   same as what's already given), and topic(s), and invoke both broadcasts with
  #   relevant identifiers, topics, and result

  # WISHLIST
  #
  # sessions.ex:
  # - notify_subscribers(event) :: nil
  #   - Maybe make some kind of helper for ({:ok, result}, event_type) -> event
  #   - might actually only need the helper since publish_event is what i really want here
  #
  # events.ex
  # - publish_event(event) :: nil


  # TODO: What if we want to trigger multiple absinthe fields from one thing that happened?
  # - Would need (event -> [{field, topic[]}])
  # - Would need a disconnect between internal concept of "thing that happened"
  #   and "thing that got triggered" (right now they are both just the event identifier)
  # - Does that make sense within the scope of the internal application? Where might I
  #   even use this functionality within absinthe? Maybe come back to this when I'm working
  #   with real full pages since maybe there's something there.

  alias CuberacerLive.Events.Event

  def publish_event(event) do
    topics = Event.topic(event)

    publish_to_pubsub(event, topics)
    publish_to_absinthe(event, topics)
  end

  defp publish_to_pubsub(event, topics) do
    Phoenix.PubSub.broadcast(
      CuberacerLive.PubSub,
      topics,
      {__MODULE__, event}
    )
  end

  defp publish_to_absinthe(event, topics) do
    field = Event.absinthe_field(event)
    result = Event.result(event)

    Absinthe.Subscription.publish(
      CuberacerLiveWeb.Endpoint,
      result,
      [{field, topics}]
    )
  end

  defprotocol Event do
    @type t() :: struct()

    @doc """
    Returns the pubsub topic(s) for an event type.
    """
    @spec topic(t()) :: String.t() | [String.t()]
    def topic(event)

    @doc """
    Returns the Absinthe subscription field for an event type.
    """
    @spec absinthe_field(t()) :: atom()
    def absinthe_field(event)

    @doc """
    Returns the data for an event.
    """
    @spec result(t()) :: term()
    def result(event)
  end

  defmodule SolveCreated do
    @type t() :: %__MODULE__{solve: %CuberacerLive.Sessions.Solve{}}
    @enforce_keys [:solve]
    defstruct [:solve]
  end

  defimpl Event, for: SolveCreated do
    def topic(%SolveCreated{solve: solve}) do
      solve = CuberacerLive.Repo.preload(solve, :round)
      "session:#{solve.round.session_id}"
    end

    def absinthe_field(_event), do: :solve_created
    def result(%SolveCreated{solve: solve}), do: solve
  end

  defmodule SolveUpdated do
    @enforce_keys [:solve]
    defstruct [:solve]  end

  defimpl Event, for: SolveUpdated do
    def topic(%SolveUpdated{solve: solve}) do
      solve = CuberacerLive.Repo.preload(solve, :round)
      "session:#{solve.round.session_id}"
    end

    def absinthe_field(_event), do: :solve_updated
    def result(%SolveUpdated{solve: solve}), do: solve
  end

  defmodule RoundCreated do
    @enforce_keys [:round]
    defstruct [:round]
  end

  defimpl Event, for: RoundCreated do
    def topic(%RoundCreated{round: round}), do: "session:#{round.session_id}"
    def absinthe_field(_event), do: :round_created
    def result(%RoundCreated{round: round}), do: round
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
