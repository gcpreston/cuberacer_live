defmodule CuberacerLiveWeb.SessionLive.Index do
  use CuberacerLiveWeb, :live_view

  alias CuberacerLive.Sessions
  alias CuberacerLive.Sessions.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :sessions, list_sessions())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Session")
    |> assign(:session, Sessions.get_session!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Session")
    |> assign(:session, %Session{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Sessions")
    |> assign(:session, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    session = Sessions.get_session!(id)
    {:ok, _} = Sessions.delete_session(session)

    {:noreply, assign(socket, :sessions, list_sessions())}
  end

  @impl true
  def handle_event(other, params, socket) do
    IO.puts("got event #{inspect(other)} and params #{inspect(params)}")

    {:noreply, socket}
  end

  defp list_sessions do
    Sessions.list_sessions()
  end
end
