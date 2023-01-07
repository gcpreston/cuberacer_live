defmodule CuberacerLiveWeb.SessionLive.Show do
  use CuberacerLiveWeb, :live_view

  import CuberacerLiveWeb.SessionLive.Components
  import CuberacerLiveWeb.SharedUtils, only: [format_datetime: 1]

  alias CuberacerLive.{Accounts, Sessions}
  alias CuberacerLive.Sessions.{Session, Round}

  @impl true
  def mount(%{"id" => session_id}, %{"user_token" => user_token}, socket) do
    user = user_token && Accounts.get_user_by_session_token(user_token)
    session = Sessions.get_loaded_session!(session_id)

    socket =
      if !user do
        redirect(socket, to: ~p"/login")
      else
        if connected?(socket) do
          Sessions.subscribe(session_id)
        end

        socket
        |> assign(:session, session)
      end

    {:ok, socket}
  end

  ## Helpers

  # Fetch all users who participated in the session. Expects a Session
  # to be passed, at least loaded through solves.
  defp participants(%Session{rounds: rounds}) do
    Enum.reduce(
      rounds,
      MapSet.new(),
      fn round, users -> MapSet.union(round |> round_users() |> MapSet.new(), users) end
    )
  end

  defp round_users(%Round{solves: solves}) do
    Enum.map(solves, & &1.user)
  end

  ## PubSub handlers

  @impl true
  def handle_info({Sessions, [:round, :created], _round}, socket) do
    socket =
      socket
      |> assign(session: Sessions.get_loaded_session!(socket.assigns.session.id))

    {:noreply, socket}
  end

  def handle_info({Sessions, [:solve, :created], _solve}, socket) do
    socket =
      socket
      |> assign(session: Sessions.get_loaded_session!(socket.assigns.session.id))

    {:noreply, socket}
  end
end
