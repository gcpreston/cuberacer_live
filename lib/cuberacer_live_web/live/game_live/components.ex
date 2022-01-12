defmodule CuberacerLive.GameLive.Components do
  use Phoenix.Component

  alias CuberacerLive.Sessions
  alias CuberacerLive.Sessions.Round
  alias CuberacerLive.Accounts.User

  def timer(assigns) do
    ~H"""
    <div
      id="timer"
      x-data="timer"
      x-init={"hasCurrentSolve = #{@has_current_solve?}"}
      @keydown.space.window="handleSpaceDown"
      @keyup.space.window.prevent="handleSpaceUp"
      phx-hook="Timer"
    >
      <span id="time" x-text="formattedTime" :class="timeColor"></span>
    </div>
    """
  end

  def penalty_input(assigns) do
    ~H"""
    <div id="penalty-input">
      <button phx-click="penalty-ok">OK</button> | <button phx-click="penalty-plus2">+2</button> | <button phx-click="penalty-dnf">DNF</button>
    </div>
    """
  end

  def chat(assigns) do
    ~H"""
    <div id="chat" class="flex flex-col w-80 border" x-data="{
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
            <div id={"room-message-#{room_message.id}"} class="t_room-message">
              <%= CuberacerLive.Messaging.display_room_message(room_message) %>
            </div>
          <% end %>
        </div>
      </div>

      <div class="flex flex-row">
        <input
          id="chat-input"
          type="text"
          class="flex-1 border"
          x-model="message"
          x-on:focus="$store.inputFocused = true"
          x-on:blur="$store.inputFocused = false"
          x-on:keydown.enter="sendMessage"
          phx-hook="ChatInput"
        />
        <button @click="sendMessage">Send</button>
      </div>
    </div>
    """
  end

  def times_table(assigns) do
    ~H"""
    <div id="times-table" class="flex flex-col">
      <table class="divide-y divide-gray-200 border-separate">
        <thead class="bg-gray-50 sticky top-0">
          <tr>
            <%= for user <- @present_users do %>
              <th scope="col" class="border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                <%= user.username %>
              </th>
            <% end %>
          </tr>
        </thead>
        <tbody id="times-table-body" class="bg-white" phx-update="prepend">
          <%= for round <- @rounds do %>
            <tr id={"round-#{round.id}"} class="t_round-row">
              <%= for user <- @present_users do %>
                <td id={"round-#{round.id}-solve-user-#{user.id}"} class="border-b px-6 py-4 whitespace-nowrap">
                  <div class="ml-4">
                    <div class="text-sm font-medium text-gray-900">
                      <%= Sessions.display_solve(user_solve_for_round(user, round)) %>
                    </div>
                  </div>
                </td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp user_solve_for_round(%User{} = user, %Round{} = round) do
    Enum.find(round.solves, fn solve -> solve.user_id == user.id end)
  end
end
