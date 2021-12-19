defmodule CuberacerLiveWeb.GameLive.Lobby do
  use CuberacerLiveWeb, :live_view

  alias CuberacerLive.Sessions
  @impl true
  def render(assigns) do
    ~H"""
    <h1>Lobby</h1>

    <div>
    <table>
    <thead>
      <tr>
        <th>Name</th>

        <th></th>
      </tr>
    </thead>
    <tbody id="sessions">
      <%= for session <- @active_sessions do %>
        <tr id={"session-#{session.id}"}>
          <td><%= session.name %></td>

          <td>
            <span>
             <%= live_redirect "Join", to: Routes.live_path(@socket, CuberacerLiveWeb.GameLive.Room, session) %>
            </span>
          </td>
        </tr>
      <% end %>
    </tbody>
    </table>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Sessions.subscribe()
    {:ok, fetch(socket)}
  end

  defp fetch(socket) do
    # TODO: for now, every session is active
    sessions = Sessions.list_sessions()
    assign(socket, active_sessions: sessions)
  end

  @impl true
  def handle_info({Sessions, [:session | _], _}, socket) do
    {:noreply, fetch(socket)}
  end
end
