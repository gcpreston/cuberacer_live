defmodule CuberacerLiveWeb.GraphQL.Schema do
  use Absinthe.Schema
  import_types CuberacerLiveWeb.GraphQL.Schema.SessionTypes
  import_types CuberacerLiveWeb.GraphQL.Schema.AccountsTypes

  alias Absinthe.Phase.Document.Arguments.Data
  alias CuberacerLiveWeb.GraphQL.Resolvers

  query do
    @desc "Get a session"
    field :session, :session do
      arg :id, non_null(:id)
      resolve &Resolvers.Sessions.find_session/3
    end
  end

  alias CuberacerLive.Sessions.Solve
  alias CuberacerLive.Sessions.Round
  alias CuberacerLive.Accounts.User

  def context(ctx) do
    loader =
      Dataloader.new
      |> Dataloader.add_source(Solve, Solve.data())
      |> Dataloader.add_source(Round, Round.data())
      |> Dataloader.add_source(User, User.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end
