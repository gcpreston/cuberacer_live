defmodule CuberacerLiveWeb.JoinRoomForm do
  use CuberacerLiveWeb, :live_component

  alias CuberacerLive.{Accounts, Sessions}

  @impl true
  def update(%{session: session} = assigns, socket) do
    changeset = Sessions.change_session(session)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("join", %{"session" => session_params}, socket) do
    join_session(socket, session_params)
  end

  defp join_session(socket, %{"password" => password}) do
    changeset =
      socket.assigns.session
      |> Sessions.change_session()
      |> Sessions.Session.validate_current_password(password)
      |> Map.put(:action, :validate)

    case changeset.valid? do
      false ->
        {:noreply,
         socket
         |> assign(:changeset, changeset)}

      true ->
        Accounts.create_user_room_auth(%{
          user_id: socket.assigns.current_user.id,
          session_id: socket.assigns.session.id
        })

        {:noreply,
         socket
         |> push_redirect_to_room(socket.assigns.session)}
    end
  end

  defp push_redirect_to_room(socket, session) do
    socket
    |> push_redirect(to: ~p"/rooms/#{session.id}")
  end
end
