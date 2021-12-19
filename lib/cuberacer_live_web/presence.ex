defmodule CuberacerLiveWeb.Presence do
  use Phoenix.Presence,
    otp_app: :cuberacer_live,
    pubsub_server: CuberacerLive.PubSub

  alias CuberacerLive.Accounts

  def fetch(_topic, presences) do
    users = presences |> Map.keys() |> Accounts.get_users_map()

    for {key, %{metas: metas}} <- presences, into: %{} do
      {key, %{metas: metas, user: users[String.to_integer(key)]}}
    end
  end
end
