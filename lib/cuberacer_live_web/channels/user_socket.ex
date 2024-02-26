defmodule CuberacerLiveWeb.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: CuberacerLiveWeb.GraphQL.Schema

  def connect(params, socket) do
    current_user = current_user(params)

    if current_user do
      Absinthe.Phoenix.Socket.put_options(socket, context: %{
        current_user: current_user
      })

      {:ok, socket}
    else
      :error
    end
  end

  defp current_user(%{"authorization" => "Bearer " <> token}) do
    CuberacerLive.Accounts.get_user_by_bearer_token(token)
  end

  defp current_user(_), do: nil

  def id(_socket), do: nil
end
