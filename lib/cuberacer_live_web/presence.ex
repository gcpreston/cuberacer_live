defmodule CuberacerLiveWeb.Presence do
  use Phoenix.Presence,
    otp_app: :cuberacer_live,
    pubsub_server: CuberacerLive.PubSub
end
