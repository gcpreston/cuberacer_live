defmodule CuberacerLive.GameLive.Components do
  use Phoenix.Component

  def timer(assigns) do
    ~H"""
    <div
      id="timer"
      x-data="timer"
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
    <div id="chat" class="border" x-data="{
      message: '',

      sendMessage() {
        window.chatInputHook.sendMessage(this.message);
        this.$nextTick(() => {
          this.message = '';
        });
      }
    }">
      <div class="h-44 flex flex-col-reverse overflow-auto">
        <div id="room-messages" phx-update="append">
          <%= for room_message <- @room_messages do %>
            <div id={"room-message-#{room_message.id}"} class="h-8 t_room-message">
              <%= CuberacerLive.Messaging.display_room_message(room_message) %>
            </div>
          <% end %>
        </div>
      </div>

      <input
        id="chat-input"
        type="text"
        class="border"
        x-model="message"
        x-on:focus="$store.inputFocused = true"
        x-on:blur="$store.inputFocused = false"
        x-on:keydown.enter="sendMessage"
        phx-hook="ChatInput"
      />
      <button @click="sendMessage">Send</button>
    </div>
    """
  end
end
