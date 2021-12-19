defmodule CuberacerLive.Cubing do
  @moduledoc """
  The Cubing context.
  """
  import Ecto.Query, only: [from: 2]

  alias CuberacerLive.Repo
  alias CuberacerLive.Cubing.Penalty

  def get_penalty(name) do
    query = from p in Penalty, where: p.name == ^name
    Repo.one(query)
  end
end
