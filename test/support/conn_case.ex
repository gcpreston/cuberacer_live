defmodule CuberacerLiveWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use CuberacerLiveWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  @presence_shutdown_timer_ms 10

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import CuberacerLiveWeb.ConnCase
      import AssertHTML

      alias CuberacerLiveWeb.Router.Helpers, as: Routes

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

    # Shut down room servers
    for session_id <- CuberacerLive.RoomCache.list_room_ids() do
      pid = CuberacerLive.RoomServer.whereis(session_id)
      GenServer.stop(pid)
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = CuberacerLive.AccountsFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = CuberacerLive.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  @doc """
  Stops a LiveView process, as if the user closed the window.

  Can sometimes take some time to propagate changes, which I'm not
  sure why, because the same isn't true for starting a LiveView.
  If this is the case, :timer.sleep(2) should solve the problem.
  """
  def exit_liveview(lv) do
    %{proxy: {_ref, _topic, proxy_pid}} = lv
    Phoenix.LiveViewTest.ClientProxy.stop(proxy_pid, :shutdown)
  end
end
