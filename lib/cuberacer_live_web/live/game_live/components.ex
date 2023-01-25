defmodule CuberacerLiveWeb.GameLive.Components do
  use CuberacerLiveWeb, :component

  alias CuberacerLive.ParticipantDataEntry
  alias CuberacerLive.Sessions
  alias CuberacerLive.Sessions.Round
  alias CuberacerLive.Accounts.User

  attr :participant_count, :integer, required: true
  attr :session, :any, required: true, doc: "The Sessions.Session to display."

  def room_card(assigns) do
    ~H"""
    <div
      id={"t_room-card-#{@session.id}"}
      class="t_room-card relative p-4 rounded-lg shadow-sm border bg-white transition-all hover:bg-gray-50 hover:shadow-md"
    >
      <%= if @participant_count > 0 do %>
        <span class="absolute top-2 left-2 bg-green-500 h-3 w-3 rounded-full" />
      <% end %>

      <%= if Sessions.private?(@session) do %>
        <span class="absolute top-2 right-2"><i class="fas fa-lock"></i></span>
      <% end %>

      <div class="text-center">
        <span class="text-lg font-medium"><%= @session.name %></span>
      </div>
      <hr class="my-2" />
      <ul class="text-center">
        <li class="t_room-puzzle">
          <span class="font-semibold">Puzzle: </span><%= @session.puzzle_type %>
        </li>
        <li class="t_room-participants">
          <span class="font-semibold">Participants: </span><%= @participant_count %>
        </li>
      </ul>
    </div>
    """
  end

  attr :current_solve, :any, required: true, doc: "See Sessions.get_current_solve/2."
  attr :spectating, :boolean, required: true

  def timer(assigns) do
    ~H"""
    <div
      id="timer"
      x-init={"initialize(#{if @current_solve, do: @current_solve.time, else: "null"}, #{@spectating})"}
    >
      <span id="time" x-text="formattedTime" x-bind:class="timeColor"></span>
    </div>
    """
  end

  def keyboard_input(assigns) do
    ~H"""
    <.form :let={f} id="keyboard-input" for={:keyboard_input} phx-submit="keyboard-submit">
      <div>
        <%= text_input(f, :time,
          class: "w-72 mx-auto border border-gray-400 rounded-md bg-gray-50",
          pattern: "^(\\d{1,2}:)?\\d{1,2}(\\.\\d{0,3}?)?$",
          title: "MM:SS.DDD"
        ) %>
      </div>
    </.form>
    """
  end

  def penalty_input(assigns) do
    ~H"""
    <div id="penalty-input">
      <button phx-click="change-penalty" phx-value-penalty="OK">OK</button>
      | <button phx-click="change-penalty" phx-value-penalty="+2">+2</button>
      | <button phx-click="change-penalty" phx-value-penalty="DNF">DNF</button>
    </div>
    """
  end

  attr :room_messages, :list, required: true, doc: "See Messaging.list_room_messages/1."
  attr :color_seed, :any, required: true

  def chat(assigns) do
    ~H"""
    <div
      id="chat"
      class="flex flex-col border h-full w-full"
      x-data="{
      message: '',

      sendMessage() {
        window.chatInputHook.sendMessage(this.message);
        this.$nextTick(() => {
          this.message = '';
        });
      }
    }"
    >
      <div class="flex-1 flex flex-col-reverse overflow-auto">
        <div id="room-messages" phx-update="append" class="divide-y">
          <%= for room_message <- @room_messages do %>
            <.chat_message
              room_message={CuberacerLive.Repo.preload(room_message, :user)}
              color_seed={@color_seed}
            />
          <% end %>
        </div>
      </div>

      <div class="flex flex-row">
        <input
          id="chat-input"
          type="text"
          class="flex-1 border rounded-xl px-2 py-1 mx-2 my-1"
          placeholder="Chat"
          x-model="message"
          x-on:focus="$store.inputFocused = true"
          x-on:blur="$store.inputFocused = false"
          x-on:keydown.enter="sendMessage"
          phx-hook="ChatInput"
        />
        <button @click="sendMessage" class="font-medium mr-2 text-cyan-600 hover:text-cyan-800">
          Send
        </button>
      </div>
    </div>
    """
  end

  attr :participants, :map, required: true, doc: "ParticipantData for participants"
  attr :current_round, :any, required: true, doc: "The current Sessions.Round for this session."
  attr :past_rounds, :list, required: true, doc: "The previous Sessions.Rounds for this session."

  def times_table(assigns) do
    # Taps into 'room' Alpine data
    assigns = assign(assigns, :participants_with_index, Enum.with_index(assigns.participants))

    ~H"""
    <table
      id="times-table"
      class="table-fixed w-full border-separate [border-spacing:0]"
      x-init="calibratePagination()"
    >
      <thead class="bg-gray-50 sticky top-0">
        <tr class="flex">
          <%= for {{user_id, entry}, i} <- @participants_with_index do %>
            <th
              scope="col"
              id={"header-cell-user-#{user_id}"}
              class="w-28 border-y px-2 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider flex"
              x-bind:class={"{ 'hidden': !isColShown(#{i}) }"}
            >
              <div class="inline-flex max-w-full">
                <span class="flex-1 truncate">
                  <.link href={~p"/users/#{user_id}"} target="_blank">
                    <%= entry.user.username %>
                  </.link>
                </span>
                <%= if ParticipantDataEntry.get_time_entry(entry) == :keyboard do %>
                  <span class="text-center pl-1">
                    <i class="fas fa-keyboard" title="This player is using keyboard entry"></i>
                  </span>
                <% end %>
              </div>
            </th>
          <% end %>
          <th class="flex-1 border-y"></th>
        </tr>
      </thead>
      <tbody id="times-table-body" class="bg-white" x-show="bottomBarShow" phx-update="prepend">
        <tr id={"round-#{@current_round.id}"} class="flex t_round-row" title={@current_round.scramble}>
          <%= for {{user_id, entry}, i} <- @participants_with_index do %>
            <td
              id={"round-#{@current_round.id}-solve-user-#{user_id}"}
              class="w-28 border-b px-2 py-4 whitespace-nowrap"
              x-show={"isColShown(#{i})"}
            >
              <div
                id={"t_cell-round-#{@current_round.id}-user-#{user_id}"}
                class="text-sm font-medium text-center text-gray-900"
              >
                <%= if ParticipantDataEntry.get_solving(entry) do %>
                  Solving...
                <% else %>
                  <%= user_solve_for_round(entry.user, @current_round) |> Sessions.display_solve() %>
                <% end %>
              </div>
            </td>
          <% end %>
          <td class="flex-1 border-b"></td>
        </tr>
        <%= for round <- @past_rounds do %>
          <tr id={"round-#{round.id}"} class="flex t_round-row" title={round.scramble}>
            <%= for {{user_id, data}, i} <- @participants_with_index do %>
              <td
                id={"round-#{round.id}-solve-user-#{user_id}"}
                class="w-28 border-b px-2 py-4 whitespace-nowrap"
                x-show={"isColShown(#{i})"}
              >
                <div
                  id={"t_cell-round-#{round.id}-user-#{user_id}"}
                  class="text-sm font-medium text-center text-gray-900"
                >
                  <%= user_solve_for_round(data.user, round) |> Sessions.display_solve() %>
                </div>
              </td>
            <% end %>
            <td class="flex-1 border-b"></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  defp user_solve_for_round(%User{} = user, %Round{} = round) do
    Enum.find(round.solves, fn solve -> solve.user_id == user.id end)
  end

  attr :ao5, :float, required: true
  attr :ao12, :float, required: true

  def stats(assigns) do
    # Taps into 'room' Alpine data
    ~H"""
    <table class="w-full" id="stats">
      <thead class="bg-gray-50" @touchstart="handleBottomBarTap" @dblclick="bottomBarFull">
        <tr>
          <th
            scope="col"
            class="border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
          >
            <span class="inline-block mr-1" @click="bottomBarCollapse">
              <i
                class="fas"
                x-bind:class="bottomBarShow ? 'fa-chevron-circle-down' : 'fa-chevron-circle-up'"
              >
              </i>
            </span>
            <span>Stats</span>
          </th>
        </tr>
      </thead>
      <tbody class="bg-white" x-show="bottomBarShow">
        <tr>
          <td class="px-6 whitespace-nowrap">
            ao5: <span class="t_ao5"><%= Sessions.display_stat(@ao5) %></span>
          </td>
        </tr>
        <tr>
          <td class="px-6 whitespace-nowrap">
            ao12: <span class="t_ao12"><%= Sessions.display_stat(@ao12) %></span>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  attr :num_participants, :integer, required: true
  attr :num_spectators, :integer, required: true

  def presence(assigns) do
    # Taps into 'room' Alpine data
    ~H"""
    <table class="w-full mb-4" x-show="bottomBarShow">
      <thead class="bg-gray-50">
        <tr>
          <th
            scope="col"
            class="border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
          >
            Presence
          </th>
        </tr>
      </thead>
      <tbody class="bg-white">
        <tr>
          <td class="px-6 whitespace-nowrap">
            <%= @num_participants %> <%= Inflex.inflect("participant", @num_participants) %>
          </td>
        </tr>
        <tr :if={@num_spectators > 0}>
          <td class="px-6 whitespace-nowrap">
            <%= @num_spectators %> <%= Inflex.inflect("spectator", @num_spectators) %>
          </td>
        </tr>
        <tr x-show="numUsersPages > 1">
          <td class="px-6 whitespace-nowrap">
            Page <span x-text="usersPage"></span>/<span x-text="numUsersPages"></span>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end
end
