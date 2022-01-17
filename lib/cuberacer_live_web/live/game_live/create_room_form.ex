defmodule CuberacerLiveWeb.GameLive.CreateRoomForm do
  use CuberacerLiveWeb, :live_component

  alias CuberacerLive.{Cubing, Sessions}

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

  defp save_session(socket, :new, %{"name" => name, "cube_type_id" => cube_type_id}) do
    case Sessions.create_session_and_round(name, cube_type_id) do
      {:ok, _session, _round} ->
        {:noreply,
         socket
         |> put_flash(:info, "Session created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp cube_type_options do
    cube_types =
      Cubing.list_cube_types()
      |> Enum.filter(fn ct -> ct.name in Whisk.puzzle_types() end)

    for cube_type <- cube_types do
      [key: cube_type.name, value: cube_type.id]
    end
  end
end
