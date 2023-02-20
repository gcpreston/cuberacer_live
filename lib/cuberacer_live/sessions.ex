defmodule CuberacerLive.Sessions do
  @moduledoc """
  The Sessions context.
  """

  ## DATA DEFINITIONS

  # A time is a int, the number of milliseconds a solve took.

  # A stat is a float, a calculation on a set of times.

  ## ----------------

  import Ecto.Query, warn: false

  alias CuberacerLive.Repo
  alias CuberacerLive.Stats
  alias CuberacerLive.Sessions.{Session, Round, Solve}
  alias CuberacerLive.Accounts
  alias CuberacerLive.Accounts.User

  @topic inspect(__MODULE__)

  def subscribe do
    Phoenix.PubSub.subscribe(CuberacerLive.PubSub, @topic)
  end

  def subscribe(session_id) do
    Phoenix.PubSub.subscribe(CuberacerLive.PubSub, @topic <> "#{session_id}")
  end

  @doc """
  Returns the list of sessions.

  ## Examples

      iex> list_sessions()
      [%Session{}, ...]

  """
  def list_sessions do
    query = from s in Session, order_by: [desc: s.inserted_at]
    Repo.all(query)
  end

  @doc """
  Returns a list of sessions (past and current) which the given
  user has participated in.
  """
  def list_user_sessions(%User{id: user_id}) do
    query = user_sessions_query(user_id)
    Repo.all(query)
  end

  defp user_sessions_query(user_id) do
    from session in Session,
      distinct: true,
      left_join: round in assoc(session, :rounds),
      left_join: solve in assoc(round, :solves),
      left_join: message in assoc(session, :room_messages),
      where: solve.user_id == ^user_id,
      or_where: message.user_id == ^user_id,
      or_where: session.host_id == ^user_id,
      order_by: [desc: session.id],
      select: session
  end

  @doc """
  Returns a list of sessions (past and current) which
  1. the first user has participated in
  2. are visible to the second user
  """
  def list_visible_user_sessions(%User{id: user_id}, %User{id: current_user_id}) do
    query =
      from session in user_sessions_query(user_id),
        left_join: auth in assoc(session, :user_room_auths),
        where: is_nil(session.hashed_password),
        or_where: auth.user_id == ^current_user_id

    Repo.all(query)
  end

  @doc """
  Gets a single session.

  Raises `Ecto.NoResultsError` if the Session does not exist.

  ## Examples

      iex> get_session!(123)
      %Session{}

      iex> get_session!(456)
      ** (Ecto.NoResultsError)

  """
  def get_session!(id), do: Repo.get!(Session, id)

  @doc """
  Gets a single session.

  Returns `nil` if the Session does not exist.

  ## Examples

      iex> get_session(123)
      %Session{}

      iex> get_session(456)
      nil

  """
  def get_session(id) when is_integer(id) do
    Repo.get(Session, id)
  end

  def get_session(id) when is_binary(id) do
    case Integer.parse(id) do
      {int_id, ""} -> get_session(int_id)
      _ -> nil
    end
  end

  @doc """
  Gets a list of sessions, given a list of session IDs.

  The returned list is not guaranteed to maintain the same session
  order as the given list.

  If a session ID does not exist, no such session is included
  in the returned list.

  ## Examples

      iex> get_sessions([1, 2, 3])
      [%Session{}, %Session{}, %Session]

      iex> get_sessions([123, 456])
      [%Session{id: 123}]

  """
  def get_sessions(ids) when is_list(ids) do
    query = from s in Session, where: s.id in ^ids
    Repo.all(query)
  end

  @doc """
  Gets a single session, fully preloaded with rounds, solves, messages, etc.

  Raises `Ecto.NoResultsError` if the Session does not exist.
  """
  def get_loaded_session!(id) do
    query =
      from session in Session,
        left_join: message in assoc(session, :room_messages),
        left_join: round in assoc(session, :rounds),
        left_join: solve in assoc(round, :solves),
        left_join: user in assoc(solve, :user),
        where: session.id == ^id,
        order_by: [desc: round.id, asc: message.id],
        preload: [
          room_messages: message,
          rounds: {round, solves: {solve, user: user}}
        ]

    Repo.one!(query)
  end

  @doc """
  Creates a session.

  ## Examples

      iex> create_session(%{field: value})
      {:ok, %Session{}}

      iex> create_session(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_session(attrs \\ %{}) do
    %Session{}
    |> Session.create_changeset(attrs)
    |> Repo.insert()
    |> notify_subscribers([:session, :created])
  end

  @doc """
  Creates a session and an initial round.

  ## Examples

      iex> create_session_and_round("my cool sesh", "3x3")
      {:ok, %Session{}, %Round{}}

      iex> create_session_and_round(nil, %CubeType{}, "strongpassword123", %User{})
      {:error, %Ecto.Changeset{}}

  """
  def create_session_and_round(name, puzzle_type, password \\ nil, host \\ nil) do
    host_id = if match?(%User{}, host), do: host.id, else: nil

    session_attrs = %{
      host_id: host_id,
      name: name,
      puzzle_type: puzzle_type,
      password: password
    }

    with {:ok, session} <- create_session(session_attrs),
         {:ok, round} <- create_round(session) do
      if password && host do
        Accounts.create_user_room_auth(%{user_id: host.id, session_id: session.id})
      end

      {:ok, session, round}
    else
      err -> err
    end
  end

  @doc """
  Updates a session.

  ## Examples

      iex> update_session(session, %{field: new_value})
      {:ok, %Session{}}

      iex> update_session(session, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_session(%Session{} = session, attrs) do
    session
    |> Session.changeset(attrs)
    |> Repo.update()
    |> notify_subscribers([:session, :updated])
  end

  @doc """
  Deletes a session.

  ## Examples

      iex> delete_session(session)
      {:ok, %Session{}}

      iex> delete_session(session)
      {:error, %Ecto.Changeset{}}

  """
  def delete_session(%Session{} = session) do
    Repo.delete(session)
    |> notify_subscribers([:session, :deleted])
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking session changes.

  ## Examples

      iex> change_session(session)
      %Ecto.Changeset{data: %Session{}}

  """
  def change_session(%Session{} = session, attrs \\ %{}) do
    Session.changeset(session, attrs)
  end

  @doc """
  Determine if the passed session is private.
  """
  def private?(%Session{} = session) do
    !!session.hashed_password
  end

  @doc """
  Returns the list of rounds.

  ## Examples

      iex> list_rounds()
      [%Round{}, ...]

  """
  def list_rounds do
    Repo.all(Round)
  end

  @doc """
  Returns the list of rounds in a session. Preloads `:solves` and
  `:penalty` of each solve.

  `order` can be specified as `:asc` (default) or `:desc`.

  ## Examples

      iex> list_rounds_of_session(%Session{})
      [%Round{}, ...]

      iex> list_rounds_of_session(%Session{}, :desc)
      [%Round{id: 3}, %Round{id: 2}, ...]

  """
  def list_rounds_of_session(%Session{id: session_id}, order \\ :asc) do
    # TODO: Didn't remember that this was loading solves and penalties until now. I don't think
    # this is necessary because of how times_table is implemented.
    query =
      from r in Round,
        where: r.session_id == ^session_id,
        left_join: s in assoc(r, :solves),
        order_by: [{^order, r.id}],
        preload: [solves: s]

    Repo.all(query)
  end

  @doc """
  Gets a single round.

  Raises `Ecto.NoResultsError` if the Round does not exist.

  ## Examples

      iex> get_round!(123)
      %Round{}

      iex> get_round!(456)
      ** (Ecto.NoResultsError)

  """
  def get_round!(id), do: Repo.get!(Round, id)

  @doc """
  Gets a single round, preloaded.

  Raises `Ecto.NoResultsError` if the Round does not exist.
  """
  def get_loaded_round!(id) do
    query =
      from round in Round,
        join: session in assoc(round, :session),
        left_join: solve in assoc(round, :solves),
        left_join: user in assoc(solve, :user),
        where: round.id == ^id,
        preload: [session: session, solves: {solve, user: user}]

    Repo.one!(query)
  end

  @doc """
  Get the most recent round of a session.

  Raises `Ecto.NoResultsError` if the session has no rounds.
  """
  def get_current_round!(%Session{id: session_id}) do
    query = current_round_query(session_id)
    Repo.one!(query)
  end

  defp current_round_query(session_id) do
    from r in Round,
      where: r.session_id == ^session_id,
      order_by: [desc: r.id],
      limit: 1
  end

  @doc """
  Creates a round. If a scramble is not provided, generates a random one.

  ## Examples

      iex> create_round(%Session{})
      {:ok, %Round{}}

      iex> create_round(%Session{}, "R U R' U'")
      {:ok, %Round{}}

      iex> create_round(%Session{}, true)
      {:error, %Ecto.Changeset{}}

  """
  def create_round(%Session{} = session, scramble \\ nil) do
    scramble = scramble || Whisk.scramble(session.puzzle_type)
    attrs = %{session_id: session.id, scramble: scramble}

    %Round{}
    |> Round.create_changeset(attrs)
    |> Repo.insert()
    |> notify_subscribers([:round, :created])
  end

  @doc """
  Deletes a round.

  ## Examples

      iex> delete_round(round)
      {:ok, %Round{}}

      iex> delete_round(round)
      {:error, %Ecto.Changeset{}}

  """
  def delete_round(%Round{} = round) do
    Repo.delete(round)
    |> notify_subscribers([:round, :deleted])
  end

  @doc """
  Returns the list of solves.

  ## Examples

      iex> list_solves()
      [%Solve{}, ...]

  """
  def list_solves do
    Repo.all(Solve)
  end

  @doc """
  Returns the list of solves in a session.

  ## Examples

      iex> list_solves_of_session(%Session{})
      [%Solve{}, ...]

  """
  def list_solves_of_session(%Session{} = session) do
    query =
      from s in Solve,
        join: r in assoc(s, :round),
        where: r.session_id == ^session.id

    Repo.all(query)
  end

  @doc """
  Gets a single solve.

  Raises `Ecto.NoResultsError` if the Solve does not exist.

  ## Examples

      iex> get_solve!(123)
      %Solve{}

      iex> get_solve!(456)
      ** (Ecto.NoResultsError)

  """
  def get_solve!(id), do: Repo.get!(Solve, id)

  @doc """
  Gets a single solve, preloaded.

  Raises `Ecto.NoResultsError` if the Solve does not exist.
  """
  def get_loaded_solve!(id) do
    query =
      from solve in Solve,
        join: user in assoc(solve, :user),
        join: round in assoc(solve, :round),
        join: session in assoc(solve, :session),
        where: solve.id == ^id,
        preload: [
          user: user,
          round: round,
          session: session
        ]

    Repo.one!(query)
  end

  @doc """
  Get a user's solve in the current round of a session.

  Returns `nil` if the user has no solve for the current round.
  """
  def get_current_solve(%Session{id: session_id}, %User{id: user_id}) do
    query =
      from r in subquery(current_round_query(session_id)),
        join: s in assoc(r, :solves),
        where: s.user_id == ^user_id,
        select: s

    Repo.one(query)
  end

  @doc """
  Creates a solve.

  ## Examples

      iex> create_solve(%{field: value})
      {:ok, %Solve{}}

      iex> create_solve(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_solve(attrs \\ %{}) do
    %Solve{}
    |> Solve.create_changeset(attrs)
    |> Repo.insert()
    |> notify_subscribers([:solve, :created])
  end

  @doc """
  Submit a solve for a user.

  Adds the solve to the current round of the given session.

  ## Examples

      iex> create_solve(%Session{}, %User{}, 9905, "OK")
      %Solve{}

      iex> create_solve(%Session{}, %User{}, 51423, "+2")
      %Solve{}

  """
  def create_solve(%Session{} = session, %User{} = user, time, penalty) do
    round = get_current_round!(session)
    attrs = %{round_id: round.id, user_id: user.id, time: time, penalty: penalty}

    %Solve{}
    |> Solve.create_changeset(attrs)
    |> Repo.insert()
    |> notify_subscribers([:solve, :created])
  end

  @doc """
  Change the penalty on a solve.

  ## Examples

      iex> change_penalty(solve, "DNF")
      {:ok, %Solve{penalty: :DNF}}

  """
  def change_penalty(%Solve{} = solve, penalty) do
    solve
    |> Solve.penalty_changeset(%{penalty: penalty})
    |> Repo.update()
    |> notify_subscribers([:solve, :updated])
  end

  @doc """
  Deletes a solve.

  ## Examples

      iex> delete_solve(solve)
      {:ok, %Solve{}}

      iex> delete_solve(solve)
      {:error, %Ecto.Changeset{}}

  """
  def delete_solve(%Solve{} = solve) do
    Repo.delete(solve)
    |> notify_subscribers([:solve, :deleted])
  end

  @doc """
  Return a string of a solve time in seconds and penalty.

  Accepts `nil` as well, returning a placeholder value.

  ## Examples

      iex> display_solve(ok_solve)
      "12.345"

      iex> display_solve(plus2_solve)
      "14.345+"

      iex> display_solve(dnf_solve)
      "DNF"

      iex> display_solve(nil)
      "--"

  """
  def display_solve(solve) do
    case solve do
      nil -> "--"
      %Solve{penalty: :OK} -> ms_to_time_str(solve.time)
      %Solve{penalty: :"+2"} -> ms_to_time_str(solve.time + 2000) <> "+"
      %Solve{penalty: :DNF} -> "DNF"
    end
  end

  @doc """
  Return the string representation of a stat.
  """
  def display_stat(:dnf) do
    "DNF"
  end

  def display_stat(time) do
    time |> trunc() |> ms_to_time_str()
  end

  @doc """
  Get the time of a solve after applying its penalty.

  If the penalty is DNF, or if the solve is `nil`, returns `:dnf`.
  """
  def actual_time(%Solve{} = solve) do
    case solve.penalty do
      :OK -> solve.time
      :"+2" -> solve.time + 2000
      :DNF -> :dnf
    end
  end

  def actual_time(nil) do
    :dnf
  end

  @doc """
  Get stats for a user in a session.

  Stats calculated are:
  - current average of 5
  - current average of 12
  """
  def current_stats(%Session{id: session_id}, %User{id: user_id}) do
    query =
      from r in Round,
        where: r.session_id == ^session_id,
        left_join: s in assoc(r, :solves),
        order_by: [desc: r.id],
        preload: [solves: s]

    rounds = Repo.all(query)

    solves =
      Enum.map(rounds, fn round ->
        Enum.find(round.solves, fn solve -> solve.user_id == user_id end)
      end)

    # Don't count the current round if a time isn't submitted yet
    solves =
      case solves do
        [nil | rest] -> rest
        _ -> solves
      end

    times = Enum.map(solves, &actual_time/1)

    %{ao5: Stats.avg_n(times, 5), ao12: Stats.avg_n(times, 12)}
  end

  defp ms_to_time_str(ms) do
    seconds = ms |> div(1000) |> rem(60)
    milliseconds = rem(ms, 1000)
    padded_milliseconds = String.pad_leading("#{milliseconds}", 3, "0")

    if ms < 60_000 do
      "#{seconds}.#{padded_milliseconds}"
    else
      minutes = ms |> div(60_000) |> rem(60)
      padded_seconds = String.pad_leading("#{seconds}", 2, "0")
      "#{minutes}:#{padded_seconds}.#{padded_milliseconds}"
    end
  end

  ## Notify subscribers
  # - on session create/update, notify overall topic as well as session topic
  # - on round/solve create/update, notify only the session topic

  defp notify_subscribers({:ok, %Session{} = result}, [:session, _action] = event) do
    Phoenix.PubSub.broadcast(CuberacerLive.PubSub, @topic, {__MODULE__, event, result})

    Phoenix.PubSub.broadcast(
      CuberacerLive.PubSub,
      @topic <> "#{result.id}",
      {__MODULE__, event, result}
    )

    {:ok, result}
  end

  defp notify_subscribers({:ok, %Round{} = result}, [:round, _action] = event) do
    session_id = result.session_id

    Phoenix.PubSub.broadcast(
      CuberacerLive.PubSub,
      @topic <> "#{session_id}",
      {__MODULE__, event, result}
    )

    {:ok, result}
  end

  defp notify_subscribers({:ok, %Solve{} = result}, [:solve, _action] = event) do
    preloaded_solve = Repo.preload(result, :round)

    Phoenix.PubSub.broadcast(
      CuberacerLive.PubSub,
      @topic <> "#{preloaded_solve.round.session_id}",
      {__MODULE__, event, preloaded_solve}
    )

    {:ok, preloaded_solve}
  end

  defp notify_subscribers({:error, reason}, _event), do: {:error, reason}
end
