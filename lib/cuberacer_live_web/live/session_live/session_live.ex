defmodule CuberacerLiveWeb.SessionLive do
  use CuberacerLiveWeb, :live_view

  import CuberacerLiveWeb.SessionComponents
  import CuberacerLiveWeb.SharedUtils, only: [format_datetime: 1]

  alias CuberacerLive.Sessions

  @impl true
  def mount(%{"id" => locator}, %{"user_token" => _user_token}, socket) do
    # TODO: What kind of authentication is needed here?
    {used_session_id, session_id} = Sessions.parse_session_locator(locator)

    socket =
      if is_nil(session_id) do
        push_redirect_to_lobby(socket, "Unknown session")
      else
        if connected?(socket) do
          Sessions.subscribe(session_id)
        end

        socket
        |> assign(:session_id, session_id)
        |> fetch_session()
      end

    {:ok, socket}
  end

  @impl true
  def handle_info({Sessions, [:session, :deleted], _session}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Session was deleted")
     |> push_redirect(to: Routes.game_lobby_path(socket, :index))}
  end

  def handle_info({Sessions, _event, _model}, socket) do
    {:noreply, socket |> fetch_session()}
  end

  defp fetch_session(socket) do
    session = Sessions.get_loaded_session!(socket.assigns.session_id)
    assign(socket, :session, session)
  end

  defp push_redirect_to_lobby(socket, flash_error) do
    socket
    |> put_flash(:error, flash_error)
    |> push_redirect(to: Routes.game_lobby_path(socket, :index))
  end
end
