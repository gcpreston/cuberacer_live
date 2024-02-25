defmodule CuberacerLiveWeb.GraphQL.Schema.AccountsTypes do
  use Absinthe.Schema.Notation

  @desc "A user of the platform"
  object :user do
    field :id, :id
    field :username, :string
  end
end
