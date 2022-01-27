defmodule CuberacerLiveWeb.RoomChannel do
  use CuberacerLiveWeb, :channel

  alias CuberacerLive.Repo
  alias CuberacerLive.{Cubing, Sessions, Messaging}
  alias CuberacerLiveWeb.Presence

  @impl true
  def join("room:" <> room_id, _payload, socket) do
    send(self(), :after_join)

    Sessions.subscribe(room_id)
    Messaging.subscribe(room_id)
    session = Sessions.get_room_data!(room_id)
    {:ok, session, socket}
  end

  @impl true
  def handle_in("new_round", _payload, socket) do
    Sessions.create_round(session_id(socket))
    {:noreply, socket}
  end

  def handle_in("new_solve", %{"time" => time}, socket) do
    penalty = Cubing.get_penalty("OK")
    Sessions.create_solve(session_id(socket), socket.assigns.user_id, time, penalty.id)
    {:noreply, socket}
  end

  def handle_in("change_penalty", %{"penalty" => penalty_name}, socket) do
    if solve = Sessions.get_current_solve(session_id(socket), socket.assigns.user_id) do
      Sessions.change_penalty(solve, Cubing.get_penalty(penalty_name))
    end

    {:noreply, socket}
  end

  def handle_in("send_message", %{"message" => message}, socket) do
    Messaging.create_room_message(session_id(socket), socket.assigns.user_id, message)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      online_at: inspect(System.system_time(:second))
    })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  def handle_info({Sessions, [:round, :created], round}, socket) do
    round = Repo.preload(round, :solves)
    push(socket, "round_created", round)
    {:noreply, socket}
  end

  def handle_info({Sessions, [:solve, :created], solve}, socket) do
    solve = Repo.preload(solve, :penalty)
    push(socket, "solve_created", solve)
    {:noreply, socket}
  end

  def handle_info({Sessions, [:solve, :updated], solve}, socket) do
    solve = Repo.preload(solve, :penalty)
    push(socket, "solve_updated", solve)
    {:noreply, socket}
  end

  def handle_info({Messaging, [:room_message, _], room_message}, socket) do
    room_message = Repo.preload(room_message, :user)
    push(socket, "message_created", room_message)
    {:noreply, socket}
  end

  defp session_id(%Phoenix.Socket{topic: "room:" <> id}), do: id
end
