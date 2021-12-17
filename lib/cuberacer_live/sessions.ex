defmodule CuberacerLive.Sessions do
  @moduledoc """
  The Sessions context.
  """

  import Ecto.Query, warn: false
  alias CuberacerLive.Repo

  alias CuberacerLive.Sessions.Session

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

  defp notify_subscribers({:ok, result}, event) do
    Phoenix.PubSub.broadcast(CuberacerLive.PubSub, @topic, {__MODULE__, event, result})

    Phoenix.PubSub.broadcast(
      CuberacerLive.PubSub,
      @topic <> "#{result.id}",
      {__MODULE__, event, result}
    )

    {:ok, result}
  end

  defp notify_subscribers({:error, reason}, _event), do: {:error, reason}

  alias CuberacerLive.Sessions.Round

  @doc """
  Returns the list of rounds.

  ## Examples

      iex> list_rounds()
      [%Round{}, ...]

  """
  def list_rounds() do
    Repo.all(Round)
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
  Creates a round.

  ## Examples

      iex> create_round(%{field: value})
      {:ok, %Round{}}

      iex> create_round(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_round(attrs \\ %{}) do
    %Round{}
    |> Round.create_changeset(attrs)
    |> Repo.insert()
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
  end

  alias CuberacerLive.Sessions.Solve
  alias CuberacerLive.Cubing.Penalty

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
  end
end
