defmodule CuberacerLiveWeb.GraphQL.Resolvers.Sessions do
  alias CuberacerLive.Sessions

  def find_session(_parent, %{id: id}, _resolution) do
    case Sessions.get_session(id) do
      nil -> {:error, "Session not found"}
      session -> {:ok, session}
    end
  end
end
