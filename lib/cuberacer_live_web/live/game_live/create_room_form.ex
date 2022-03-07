defmodule CuberacerLiveWeb.GameLive.CreateRoomForm do
  use CuberacerLiveWeb, :live_component

  alias CuberacerLive.RoomCache
  alias CuberacerLive.Sessions

  @impl true
  def update(%{session: session} = assigns, socket) do
    changeset = Sessions.change_session(session)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"session" => session_params}, socket) do
    changeset =
      socket.assigns.session
      |> Sessions.change_session(session_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"session" => session_params}, socket) do
    save_session(socket, socket.assigns.action, session_params)
  end

  defp save_session(socket, :new, %{"name" => name, "puzzle_type" => puzzle_type}) do
    case RoomCache.create_room(name, puzzle_type) do
      {:ok, _pid, _session} ->
        {:noreply,
         socket
         |> put_flash(:info, "Room created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
