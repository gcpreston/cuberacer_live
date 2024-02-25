import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :argon2_elixir, t_cost: 1, m_cost: 8

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :cuberacer_live, CuberacerLive.Repo,
  username: "postgres",
  password: "postgres",
  database: "cuberacer_live_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cuberacer_live, CuberacerLiveWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "mHxmb8cv0S6/JNWS2A036SKVlcSOeyF4IGCg2FjXAWFMHtk+rDJt8g/kJcxL55Dq",
  server: false

# In test we don't send emails.
config :cuberacer_live, CuberacerLive.Mailer, adapter: Swoosh.Adapters.Test

config :cuberacer_live, :empty_room_timeout_ms, 150

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
