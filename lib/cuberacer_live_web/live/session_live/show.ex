defmodule CuberacerLiveWeb.SessionLive.Show do
  use CuberacerLiveWeb, :live_view

  alias CuberacerLive.Sessions

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: Sessions.subscribe(id)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:session, Sessions.get_session!(id))}
  end

  defp page_title(:show), do: "Show Session"
  defp page_title(:edit), do: "Edit Session"

  @impl true
  def handle_info({Sessions, [:session, :updated], session}, socket) do
    {:noreply, assign(socket, session: session)}
  end

  @impl true
  def handle_info({Sessions, [:session, :deleted], _session}, socket) do
    {:noreply,
      socket
      |> put_flash(:info, "Session was deleted")
      |> push_redirect(to: Routes.session_index_path(socket, :index))}
  end
end
