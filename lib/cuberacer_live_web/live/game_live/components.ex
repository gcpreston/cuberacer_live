defmodule CuberacerLiveWeb.GameLive.Components do
  use Phoenix.Component

  import CuberacerLiveWeb.SharedUtils, only: [format_datetime: 1]
  import Phoenix.HTML.Link

  alias CuberacerLiveWeb.Router.Helpers, as: Routes
  alias CuberacerLive.Sessions
  alias CuberacerLive.Sessions.Round
  alias CuberacerLive.Accounts.User


  def room_card(assigns) do
    ~H"""
    <%= live_redirect to: Routes.game_room_path(CuberacerLiveWeb.Endpoint, :show, @session.id), class: "t_room-card" do %>
      <div id={"t_room-card-#{@session.id}"} class="p-4 rounded-lg shadow-sm border bg-white transition-all hover:bg-gray-50 hover:shadow-md">
        <h2 class="text-lg text-center font-medium"><%= @session.name %></h2>
        <hr class="my-2" />
        <div class="flex justify-center">
          <div><%= @session.puzzle_type %></div>
        </div>
      </div>
    <% end %>
    """
  end

  def timer(assigns) do
    ~H"""
    <div
      id="timer"
      x-data="timer"
      x-init={if @current_solve, do: "presetTime(#{@current_solve.time})", else: "hasCurrentSolve = false"}
      @keydown.space.window="handleSpaceDown"
      @keyup.space.window.prevent="handleSpaceUp"
      @touchstart="handleSpaceDown"
      @touchend="handleSpaceUp"
      phx-hook="Timer"
    >
      <span id="time" x-text="formattedTime" :class="timeColor"></span>
    </div>
    """
  end

  def penalty_input(assigns) do
    ~H"""
    <div id="penalty-input">
      <button phx-click="change-penalty" phx-value-penalty="OK">OK</button> | <button phx-click="change-penalty" phx-value-penalty="+2">+2</button> | <button phx-click="change-penalty" phx-value-penalty="DNF">DNF</button>
    </div>
    """
  end

  def chat(assigns) do
    ~H"""
    <div id="chat" class="flex flex-col border h-full w-full" x-data="{
      message: '',

      sendMessage() {
        window.chatInputHook.sendMessage(this.message);
        this.$nextTick(() => {
          this.message = '';
        });
      }
    }">
      <div class="flex-1 flex flex-col-reverse overflow-auto">
        <div id="room-messages" phx-update="append" class="divide-y">
          <%= for room_message <- @room_messages do %>
            <div
              id={"room-message-#{room_message.id}"}
              class="px-2 t_room-message"
              title={format_datetime(room_message.inserted_at)}
            >
              <%= CuberacerLive.Messaging.display_room_message(room_message) %>
            </div>
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
        <button @click="sendMessage" class="font-medium mr-2 text-cyan-600 hover:text-cyan-800">Send</button>
      </div>
    </div>
    """
  end

  def times_table(assigns) do
    ~H"""
    <table class="w-full border-separate [border-spacing:0]">
      <thead class="bg-gray-50 sticky top-0">
        <tr>
          <%= for user <- @users do %>
            <th scope="col" class="border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              <%= link user.username, to: Routes.user_profile_path(CuberacerLiveWeb.Endpoint, :show, user.id), target: "_blank" %>
            </th>
          <% end %>
        </tr>
      </thead>
      <tbody id="times-table-body" class="bg-white" phx-update="prepend">
        <%# Current round %>
        <tr id={"round-#{@current_round.id}"} class="t_round-row" title={@current_round.scramble}>
          <%= for user <- @users do %>
            <td id={"round-#{@current_round.id}-solve-user-#{user.id}"} class="border-b px-6 py-4 whitespace-nowrap">
              <div class="ml-4">
                <div id={"t_cell-round-#{@current_round.id}-user-#{user.id}"} class="text-sm font-medium text-gray-900">
                  <%= if user_is_solving?(@users_solving, user) do %>
                    Solving...
                  <% else %>
                    <%= user_solve_for_round(user, @current_round) |> Sessions.display_solve() %>
                  <% end %>
                </div>
              </div>
            </td>
          <% end %>
        </tr>
        <%# Past rounds %>
        <%= for round <- @past_rounds do %>
          <tr id={"round-#{round.id}"} class="t_round-row" title={round.scramble}>
            <%= for user <- @users do %>
              <td id={"round-#{round.id}-solve-user-#{user.id}"} class="border-b px-6 py-4 whitespace-nowrap">
                <div class="ml-4">
                  <div id={"t_cell-round-#{round.id}-user-#{user.id}"} class="text-sm font-medium text-gray-900">
                    <%= user_solve_for_round(user, round) |> Sessions.display_solve() %>
                  </div>
                </div>
              </td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  defp user_is_solving?(users_solving, %User{id: user_id}) do
    MapSet.member?(users_solving, user_id)
  end

  defp user_solve_for_round(%User{} = user, %Round{} = round) do
    Enum.find(round.solves, fn solve -> solve.user_id == user.id end)
  end

  def stats(assigns) do
    ~H"""
    <table class="w-full">
      <thead class="bg-gray-50">
        <tr>
          <th scope="col" class="border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            Stats
          </th>
        </tr>
      </thead>
      <tbody class="bg-white">
        <tr>
          <td class="px-6 whitespace-nowrap">ao5: <span class="t_ao5"><%= Sessions.display_stat(@stats.ao5) %></span></td>
        </tr>
        <tr>
          <td class="px-6 whitespace-nowrap">ao12: <span class="t_ao12"><%= Sessions.display_stat(@stats.ao12) %></span></td>
        </tr>
      </tbody>
    </table>
    """
  end

  def presence(assigns) do
    ~H"""
    <table class="w-full mb-4">
      <thead class="bg-gray-50">
        <tr>
          <th scope="col" class="border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
            Presence
          </th>
        </tr>
      </thead>
      <tbody class="bg-white">
        <tr>
          <td class="px-6 whitespace-nowrap"><%= @num_present_users %> <%= Inflex.inflect("participant", @num_present_users) %></td>
        </tr>
        <%= if @num_users_pages > 1 do %>
          <tr>
            <td class="px-6 whitespace-nowrap">Page <%= @users_page %>/<%= @num_users_pages %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
