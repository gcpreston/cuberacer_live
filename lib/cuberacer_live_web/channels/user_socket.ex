defmodule CuberacerLiveWeb.UserSocket do
  use Phoenix.Socket

  alias CuberacerLive.Repo
  alias CuberacerLive.Accounts.User

  ## Channels

  channel "room:*", CuberacerLiveWeb.RoomChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Phoenix.Token.verify(socket, "user auth", token, max_age: 86_400) do
      {:ok, user_id} ->
        socket = assign(socket, :user, Repo.get!(User, user_id))
        {:ok, socket}
      {:error, _} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.CuberacerLiveWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket), do: nil
end
