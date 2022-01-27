defmodule CuberacerLiveWeb.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use CuberacerLiveWeb.ChannelCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  @presence_shutdown_timer_ms 10

  using do
    quote do
      # Import conveniences for testing with channels
      import Phoenix.ChannelTest
      import CuberacerLiveWeb.ChannelCase

      # The default endpoint for testing
      @endpoint CuberacerLiveWeb.Endpoint
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(CuberacerLive.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    if tags[:ensure_presence_shutdown] do
      # Ensure Presence processes have shut down before test process exits
      # https://github.com/phoenixframework/phoenix/issues/3619
      on_exit(fn ->
        :timer.sleep(@presence_shutdown_timer_ms)

        for pid <- CuberacerLiveWeb.Presence.fetchers_pids() do
          ref = Process.monitor(pid)
          assert_receive {:DOWN, ^ref, _, _, _}, 1000
        end
      end)
    end

    :ok
  end
end
