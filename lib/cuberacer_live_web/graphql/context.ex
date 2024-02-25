defmodule CuberacerLiveWeb.GraphQL.Context do
  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  @doc """
  Return the current user context based on the authorization header
  """
  def build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         current_user when not is_nil(current_user) <-
           CuberacerLive.Accounts.get_user_by_bearer_token(token) do
      %{current_user: current_user}
    else
      _ -> %{}
    end
  end
end
