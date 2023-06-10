defmodule CuberacerLiveWeb.GameLive.ParticipantComponent do
  use CuberacerLiveWeb, :live_component

  alias CuberacerLive.{Sessions, Events, ParticipantDataEntry}

  defmodule UserRound do
    alias CuberacerLive.Sessions
    alias CuberacerLive.Accounts

    defstruct user_id: nil, round_id: nil, solve: nil

    def from_round(%Sessions.Round{} = round, %Accounts.User{} = user) do
      solve =
        Enum.find(round.solves, fn solve ->
          solve.user_id == user.id
        end)

      %__MODULE__{user_id: user.id, round_id: round.id, solve: solve}
    end

    def from_solve(%Sessions.Solve{} = solve) do
      %__MODULE__{user_id: solve.user_id, round_id: solve.round_id, solve: solve}
    end
  end

  def render(assigns) do
    ~H"""
    <div id={"user-#{@entry.user.id}-column"} class="w-24">
      <.table_header>
        <span id={"t_header-user-#{@entry.user.id}"} class="flex-1 truncate">
          <.link href={~p"/users/#{@entry.user.id}"} target="_blank">
            <%= @entry.user.username %>
          </.link>
          <%= if ParticipantDataEntry.get_time_entry(@entry) == :keyboard do %>
            <span class="text-center pl-1">
              <i class="fas fa-keyboard" title="This player is using keyboard entry"></i>
            </span>
          <% end %>
        </span>
      </.table_header>

      <div id={"user-#{@entry.user.id}-rounds"} class="bg-white" phx-update="stream">
        <div :for={{dom_id, user_round} <- @streams.user_rounds} id={dom_id}>
          <.table_cell>
            <span id={"t_cell-round-#{user_round.round_id}-user-#{user_round.user_id}"}>
              <%= if user_round.round_id == @current_round.id && ParticipantDataEntry.get_solving(@entry) do %>
                Solving...
              <% else %>
                <%= user_round.solve |> Sessions.display_solve() %>
              <% end %>
            </span>
          </.table_cell>
        </div>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok,
     socket
     |> stream_configure(:user_rounds, dom_id: &"user-#{&1.user_id}-round-#{&1.round_id}")}
  end

  def update(%{participant_data_entry: entry, rounds: rounds}, socket) do
    current_round = hd(rounds)
    user_rounds = Enum.map(rounds, fn round -> UserRound.from_round(round, entry.user) end)

    {:ok,
     socket
     |> assign(:entry, entry)
     |> assign(:current_round, current_round)
     |> stream(:user_rounds, user_rounds)}
  end

  def update(%{event: %Events.SolveCreated{solve: solve}}, socket) do
    {:ok, stream_insert(socket, :user_rounds, UserRound.from_solve(solve))}
  end

  def update(%{event: %Events.SolveUpdated{solve: solve}}, socket) do
    {:ok, stream_insert(socket, :user_rounds, UserRound.from_solve(solve))}
  end

  def update(%{event: %Events.RoundCreated{round: round}}, socket) do
    {:ok,
     stream_insert(socket, :user_rounds, UserRound.from_round(round, socket.assigns.entry.user),
       at: 0
     )}
  end
end
