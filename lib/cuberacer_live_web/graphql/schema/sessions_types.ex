defmodule CuberacerLiveWeb.GraphQL.Schema.SessionTypes do
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  @desc "A timed solve"
  object :solve do
    field :id, :id
    field :time, :integer
    field :penalty, :string
    field :round, :round
    field :user, :user, resolve: dataloader(CuberacerLive.Accounts.User)
  end

  @desc "A round of solves"
  object :round do
    field :id, :id
    field :scramble, :string
    field :solves, list_of(:solve), resolve: dataloader(CuberacerLive.Sessions.Solve)
    field :session, :session
  end

  @desc "A collection of rounds"
  object :session do
    field :id, :id
    field :rounds, list_of(:round), resolve: dataloader(CuberacerLive.Sessions.Round)
  end
end
