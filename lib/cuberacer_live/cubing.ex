defmodule CuberacerLive.Cubing do
  @moduledoc """
  The Cubing context.
  """
  import Ecto.Query, only: [from: 2]

  alias CuberacerLive.Repo
  alias CuberacerLive.Cubing.{CubeType, Penalty}

  @doc """
  Returns the list of cube types.

  ## Examples

      iex> list_cube_types()
      [%CubeType{}, ...]

  """
  def list_cube_types do
    Repo.all(CubeType)
  end

  @doc """
  Get a penalty by name.

  ## Examples

      iex> get_penalty("+2")
      %Penalty{name: "+2"}

      iex> get_penalty("bad val")
      nil

  """
  def get_penalty(name) do
    query = from p in Penalty, where: p.name == ^name
    Repo.one(query)
  end
end
