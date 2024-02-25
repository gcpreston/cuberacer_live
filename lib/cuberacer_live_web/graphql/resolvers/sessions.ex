defmodule CuberacerLiveWeb.GraphQL.Resolvers.Sessions do
  alias CuberacerLive.Sessions

  def find_session(_parent, %{id: id}, _resolution) do
    case Sessions.get_session(id) do
      nil -> {:error, "Session not found"}
      session -> {:ok, session}
    end
  end

  def create_round(_parent, %{session_id: session_id}, _resolution) do
    with session when not is_nil(session) <- Sessions.get_session(session_id),
         {:ok, round} <- Sessions.create_round(session) do
      {:ok, round}
    else
      _ -> {:error, "Invalid round data"}
    end
  end
end
