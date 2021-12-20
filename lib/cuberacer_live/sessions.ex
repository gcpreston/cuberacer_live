defmodule CuberacerLive.Sessions do
  @moduledoc """
  The Sessions context.
  """

  import Ecto.Query, warn: false
  alias CuberacerLive.Repo

  alias CuberacerLive.Sessions.{Session, Round, Solve}
  alias CuberacerLive.Accounts.User
  alias CuberacerLive.Cubing.Penalty

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
    Repo.all(Session)
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
  Creates a session.

  ## Examples

      iex> create_session(%{field: value})
      {:ok, %Session{}}

      iex> create_session(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_session(attrs \\ %{}) do
    %Session{}
    |> Session.changeset(attrs)
    |> Repo.insert()
    |> notify_subscribers([:session, :created])
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
  Returns the list of rounds.

  ## Examples

      iex> list_rounds()
      [%Round{}, ...]

  """
  def list_rounds do
    Repo.all(Round)
  end

  @doc """
  Returns the list of rounds in a session.

  ## Examples

      iex> list_rounds_of_session(%Session{})
      [%Round{}, ...]

  """
  def list_rounds_of_session(%Session{} = session) do
    query = from r in Round, where: r.session_id == ^session.id
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
  Get the most recent round of a session.

  Raises `Ecto.NoResultsError` if the session has no rounds.
  """
  def get_current_round(%Session{} = session) do
    query =
      from(r in Round,
        where: r.session_id == ^session.id,
        order_by: [desc: r.inserted_at],
        limit: 1
      )

    Repo.one!(query)
  end

  @doc """
  Creates a round. If a scramble is not provided, generates a random one.

  ## Examples

      iex> create_round(%{field: value})
      {:ok, %Round{}}

      iex> create_round(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_round(attrs \\ %{}) do
    attrs =
      if not Map.has_key?(attrs, :scramble) do
        Map.put(attrs, :scramble, CuberacerLive.Cubing.Utils.generate_scramble())
      else
        attrs
      end

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
  """
  def create_solve(%Session{} = session, %User{} = user, time, %Penalty{} = penalty) do
    round = get_current_round(session)
    attrs = %{user_id: user.id, time: time, penalty_id: penalty.id, round_id: round.id}

    %Solve{}
    |> Solve.create_changeset(attrs)
    |> Repo.insert()
    |> notify_subscribers([:solve, :created])
  end

  @doc """
  Change the penalty on a solve.

  ## Examples

      iex> change_penalty(solve, %Penalty{})
      {:ok, %Solve{}}

  """
  def change_penalty(%Solve{} = solve, %Penalty{} = penalty) do
    solve
    |> Solve.penalty_changeset(%{penalty_id: penalty.id})
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
    solve = Repo.preload(result, [:round, :penalty])
    session_id = solve.round.session_id

    Phoenix.PubSub.broadcast(
      CuberacerLive.PubSub,
      @topic <> "#{session_id}",
      {__MODULE__, event, solve}
    )

    {:ok, result}
  end

  defp notify_subscribers({:error, reason}, _event), do: {:error, reason}
end
