defmodule CuberacerLive.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      CuberacerLive.Repo,
      # Start the Telemetry supervisor
      CuberacerLiveWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: CuberacerLive.PubSub},
      CuberacerLive.Presence,
      # Start the Endpoint (http/https)
      CuberacerLiveWeb.Endpoint,
      # Start the Absinthe subscription server
      {Absinthe.Subscription, CuberacerLiveWeb.Endpoint},
      # Start Finch for the Mailer API client
      {Finch, name: Swoosh.Finch},
      # Start a worker by calling: CuberacerLive.Worker.start_link(arg)
      CuberacerLive.RoomCache,
      CuberacerLive.LobbyServer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CuberacerLive.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CuberacerLiveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
