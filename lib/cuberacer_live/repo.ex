defmodule CuberacerLive.Repo do
  use Ecto.Repo,
    otp_app: :cuberacer_live,
    adapter: Ecto.Adapters.Postgres
end
