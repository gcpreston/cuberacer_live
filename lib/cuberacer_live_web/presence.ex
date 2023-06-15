defmodule CuberacerLiveWeb.Presence do
  use Phoenix.Presence,
    otp_app: :cuberacer_live,
    pubsub_server: CuberacerLive.PubSub

  alias CuberacerLive.Accounts

  def init(_opts) do
    {:ok, %{}}
  end

  def fetch(_topic, presences) do
    users = presences |> Map.keys() |> Accounts.get_users_map()

    for {key, %{metas: metas}} <- presences, into: %{} do
      {key, %{metas: metas, user: users[String.to_integer(key)]}}
    end
  end

  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    for {user_id, presence} <- joins do
      user_data = %{user: presence.user, metas: Map.fetch!(presences, user_id)}
      msg = {CuberacerLive.PresenceClient, {:join, user_data}}
      Phoenix.PubSub.local_broadcast(CuberacerLive.PubSub, topic, msg)
    end

    for {user_id, presence} <- leaves do
      metas =
        case Map.fetch(presences, user_id) do
          {:ok, presence_metas} -> presence_metas
          :error -> []
        end

      # only broadcast leave if a user has left on all windows/devices
      if metas == [] do
        user_data = %{user: presence.user, metas: metas}
        msg = {CuberacerLive.PresenceClient, {:leave, user_data}}
        Phoenix.PubSub.local_broadcast(CuberacerLive.PubSub, topic, msg)
      end
    end

    {:ok, state}
  end
end
