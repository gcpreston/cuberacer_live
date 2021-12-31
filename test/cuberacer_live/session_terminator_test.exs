defmodule CuberacerLive.SessionTerminatorTest do
  use CuberacerLive.DataCase
  import CuberacerLive.SessionsFixtures

  alias CuberacerLive.SessionTerminator
  alias CuberacerLive.Sessions
  alias CuberacerLive.Sessions.Session

  @wait_time Application.get_env(:cuberacer_live, :inactive_session_lifetime_ms)

  setup do
    session = session_fixture()

    [session: session]
  end

  describe "API" do
    test "schedule_termination/1 terminates the session after the set amount of time", %{
      session: session
    } do
      SessionTerminator.schedule_termination(session)

      assert session.terminated == false

      # Not sure why it doesn't come in time with @wait_time by itself...
      :timer.sleep(@wait_time * 2)
      session = Sessions.get_session!(session.id)

      assert session.terminated
    end
  end

  describe "callbacks" do
    test ":schedule_termination sends termination message after set amount of time", %{
      session: %Session{id: session_id} = session
    } do
      assert {:noreply, %{refs: %{^session_id => _ref}}} =
               SessionTerminator.handle_cast({:schedule_termination, session}, %{refs: %{}})

      refute_received {:terminate, _}
      assert_receive {:terminate, ^session}, @wait_time * 2
    end

    test ":schedule_termination replaces an existing timer ref", %{
      session: %Session{id: session_id} = session
    } do
      old_ref = Process.send_after(self(), "some dummy message", @wait_time * 3)

      assert {:noreply, %{refs: %{^session_id => new_ref}}} =
               SessionTerminator.handle_cast({:schedule_termination, session}, %{
                 refs: %{session_id => old_ref}
               })

      assert is_reference(new_ref)
      refute new_ref == old_ref
      assert_receive {:terminate, ^session}, @wait_time * 2
      refute_receive "some dummy message", @wait_time * 4
    end

    test ":terminate terminates the given session", %{session: session} do
      assert session.terminated == false

      SessionTerminator.handle_info({:terminate, session}, %{refs: %{}})
      session = Sessions.get_session!(session.id)

      assert session.terminated
    end
  end
end
