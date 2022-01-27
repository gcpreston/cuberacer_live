defmodule CuberacerLiveWeb.RoomChannelTest do
  use CuberacerLiveWeb.ChannelCase, async: false
  @moduletag :ensure_presence_shutdown

  import CuberacerLive.AccountsFixtures
  import CuberacerLive.CubingFixtures
  import CuberacerLive.SessionsFixtures

  alias CuberacerLive.{Sessions, Messaging}
  alias CuberacerLive.Sessions.{Round, Solve}
  alias CuberacerLive.Messaging.RoomMessage

  setup do
    user = user_fixture()
    session = session_fixture()
    round = round_fixture(session: session)

    {:ok, _, socket} =
      CuberacerLiveWeb.UserSocket
      |> socket("user_socket:#{user.id}", %{user_id: user.id})
      |> subscribe_and_join(CuberacerLiveWeb.RoomChannel, "room:#{session.id}")

    %{socket: socket, user: user, session: session, round: round}
  end

  # TODO: test that channel requires auth
  # TODO: test that socket requires auth
  # TODO: implement some basic logic to handle unauthenticated room connections,
  #   even though this couldn't happen rn bc of socket auth

  describe "Presence" do
    test "pushes state on join", %{user: user} do
      user_id_str = "#{user.id}"
      assert_push "presence_state", %{^user_id_str => _}
    end

    test "broadcasts diffs on other user join and leave", %{session: session} do
      other_user = user_fixture()

      {:ok, _, other_socket} =
        CuberacerLiveWeb.UserSocket
        |> socket("user_socket:#{other_user.id}", %{user_id: other_user.id})
        |> subscribe_and_join(CuberacerLiveWeb.RoomChannel, "room:#{session.id}")

      other_user_id_str = "#{other_user.id}"

      assert_broadcast "presence_diff", %{joins: %{^other_user_id_str => _}, leaves: %{}}

      Process.unlink(other_socket.channel_pid)
      leave(other_socket)

      assert_broadcast "presence_diff", %{joins: %{}, leaves: %{^other_user_id_str => _}}
    end
  end

  describe "handle_in/3" do
    test "new_round creates a new round", %{socket: socket, session: session} do
      Sessions.subscribe(session.id)
      push(socket, "new_round")

      assert_receive {Sessions, [:round, :created], _round}
    end

    test "new_solve creates a new solve", %{socket: socket, session: session} do
      %{id: ok_penalty_id} = penalty_fixture(name: "OK")
      Sessions.subscribe(session.id)
      push(socket, "new_solve", %{"time" => 1234})

      assert_receive {Sessions, [:solve, :created],
                      %Solve{time: 1234, penalty_id: ^ok_penalty_id}}
    end

    test "change_penalty updates the current solve and pushes", %{
      socket: socket,
      session: session,
      user: %{id: user_id}
    } do
      %{id: ok_penalty_id} = penalty_fixture(name: "OK")
      %{id: dnf_penalty_id} = penalty_fixture(name: "DNF")
      Sessions.create_solve(session.id, user_id, 4321, ok_penalty_id)
      Sessions.subscribe(session.id)
      push(socket, "change_penalty", %{"penalty" => "DNF"})

      assert_receive {Sessions, [:solve, :updated],
                      %Solve{time: 4321, penalty_id: ^dnf_penalty_id}}
    end

    test "send_message creates a room message and pushes", %{
      socket: socket,
      session: session,
      user: %{id: user_id}
    } do
      Messaging.subscribe(session.id)
      push(socket, "send_message", %{"message" => "hello world"})

      assert_receive {Messaging, [:room_message, :created],
                      %RoomMessage{user_id: ^user_id, message: "hello world"}}
    end
  end

  describe "handle_info/2" do
    test "creating a round pushes to socket", %{session: session} do
      {:ok, %Round{id: round_id}} = Sessions.create_round(session)

      assert_push "round_created", %Round{id: ^round_id}
    end

    test "creating a solve pushes to socket", %{session: session, user: user} do
      penalty = penalty_fixture()
      {:ok, %Solve{id: solve_id}} = Sessions.create_solve(session, user, 4567, penalty)

      assert_push "solve_created", %Solve{id: ^solve_id}
    end

    test "changing a penalty pushes to socket", %{session: session, user: user} do
      plus2_penalty = penalty_fixture(name: "+2")
      %{id: ok_penalty_id} = ok_penalty = penalty_fixture(name: "OK")
      {:ok, %Solve{id: solve_id} = solve} = Sessions.create_solve(session, user, 4567, plus2_penalty)
      Sessions.change_penalty(solve, ok_penalty)

      assert_push "solve_updated", %Solve{id: ^solve_id, penalty_id: ^ok_penalty_id}
    end

    test "sending a message pushes to socket", %{session: session, user: user} do
      {:ok, %RoomMessage{id: room_message_id}} = Messaging.create_room_message(session, user, "does this work")

      assert_push "message_created", %RoomMessage{id: ^room_message_id, message: "does this work"}
    end
  end
end
