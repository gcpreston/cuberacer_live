defmodule CuberacerLiveWeb.GraphQL.Resolvers.Sessions do
  alias CuberacerLive.Sessions

  def find_session(_parent, %{id: id}, _resolution) do
    case Sessions.get_session(id) do
      nil -> {:error, "Session not found"}
      session -> {:ok, session}
    end
  end

  # TODO: Use functions from the Room context here, to go through the genserver

  def create_solve(
        _parent,
        %{session_id: session_id, time: time, penalty: penalty},
        %{context: %{current_user: user}}
      ) do
    with session when not is_nil(session) <- Sessions.get_session(session_id),
         {:ok, solve} <- Sessions.create_solve(session, user, time, penalty) do
      {:ok, solve}
    else
      _ -> {:error, "Invalid solve data"}
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
