defmodule CuberacerLive.Messaging do
  @moduledoc """
  The Messaging context.
  """

  import Ecto.Query, warn: false
  alias CuberacerLive.Repo

  alias CuberacerLive.Events
  alias CuberacerLive.Messaging.RoomMessage
  alias CuberacerLive.Sessions.Session
  alias CuberacerLive.Accounts.User

  @topic inspect(__MODULE__)

  def subscribe(session_id) do
    Phoenix.PubSub.subscribe(CuberacerLive.PubSub, @topic <> "#{session_id}")
  end

  @doc """
  Returns the list of messages for a room. Preloads `:user`.

  ## Examples

      iex> list_room_messages(%Session{})
      [%RoomMessage{}, ...]

  """
  def list_room_messages(%Session{id: session_id}) do
    query =
      from m in RoomMessage,
        where: m.session_id == ^session_id,
        order_by: [asc: m.id],
        preload: :user

    Repo.all(query)
  end

  @doc """
  Gets a single room_message.

  Raises `Ecto.NoResultsError` if the Room message does not exist.

  ## Examples

      iex> get_room_message!(123)
      %RoomMessage{}

      iex> get_room_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room_message!(id), do: Repo.get!(RoomMessage, id)

  @doc """
  Creates a room message.

  ## Examples

      iex> create_room_message(%Session{}, %User{}, "some message")
      {:ok, %RoomMessage{}}

      iex> create_room_message(<bad params...>)
      {:error, %Ecto.Changeset{}}

  """
  def create_room_message(%Session{id: session_id}, %User{id: user_id}, message) do
    attrs = %{message: message, user_id: user_id, session_id: session_id}

    %RoomMessage{}
    |> RoomMessage.create_changeset(attrs)
    |> Repo.insert()
    |> notify_subscribers([:room_message, :created])
  end

  defp notify_subscribers({:ok, %RoomMessage{} = result}, [:room_message, :created]) do
    Phoenix.PubSub.broadcast(
      CuberacerLive.PubSub,
      @topic <> "#{result.session_id}",
      {__MODULE__, %Events.RoomMessageCreated{room_message: result}}
    )

    {:ok, result}
  end

  defp notify_subscribers({:error, reason}, _event), do: {:error, reason}
end
