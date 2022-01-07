defmodule CuberacerLive.GameLive.Components do
  use Phoenix.Component

  def timer(assigns) do
    ~H"""
    <script>
      const READY_HOLD_TIME_MS = 500;
      const PREPARING_COLOR = 'text-red-500';
      const READY_COLOR = 'text-green-400';

      const timer = () => {
        return {
          clock: 0,
          offset: null,
          interval: null,
          readyTimeout: null,
          ready: false,
          submit: false,

          get formattedTime() {
            const secondsVal = Math.floor(this.clock / 1000) % 60;
            const millisecondsVal = this.clock % 1000;

            // if timer running, only display deciseconds
            let millisecondsStr = millisecondsVal.toString().padStart(3, '0');
            if (this.interval) {
              millisecondsStr = millisecondsStr.slice(0, 1);
            }

            if (this.clock < 60000) {
              return secondsVal + '.' + millisecondsStr;
            }

            const minutesVal = Math.floor(this.clock / 60000) % 60;
            const secondsStr = secondsVal.toString().padStart(2, '0');
            return minutesVal + ':' + secondsStr + '.' + millisecondsStr;
          },

          get timeColor() {
            if (this.ready) {
              return READY_COLOR;
            } else if (this.readyTimeout && !this.interval) {
              return PREPARING_COLOR;
            }

            return '';
          },

          handleSpaceDown() {
            if (!this.$store.inputFocused) {
              if (this.interval) {
                this.stopTime();
              } else if (!this.readyTimeout) {
                this.readyTimeout = setTimeout(() => {
                  this.resetTime();
                  this.ready = true;
                }, READY_HOLD_TIME_MS);
              }
            }
          },

          handleSpaceUp() {
            if (!this.$store.inputFocused) {
              if (this.ready) {
                this.startTime();
              } else {
                clearTimeout(this.readyTimeout);
                this.readyTimeout = null;
              }
            }
          },

          startTime() {
            if (!this.interval) {
              this.ready = false;
              this.offset = Date.now();
              this.interval = setInterval(this.updateTime.bind(this), 10);
            }
          },

          updateTime() {
            const now = Date.now();
            const delta = now - this.offset;
            this.offset = now;

            this.clock += delta;
          },

          stopTime() {
            if (this.interval) {
              clearInterval(this.interval);
              this.interval = null;
              window.timerHook.submitTime(this.clock);
            }
          },

          resetTime() {
            if (!this.interval) {
              this.clock = 0;
            }
          }
        }
      };
    </script>

    <div
      id="timer"
      x-data="timer()"
      @keydown.space.window="handleSpaceDown"
      @keyup.space.window="handleSpaceUp"
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
    <script>
      const chat = () => {
        return {
          message: '',

          sendMessage() {
            window.chatInputHook.sendMessage(this.message);
            this.$nextTick(() => {
              this.message = '';
            });
          }
        }
      };
    </script>

    <div id="chat" class="border" x-data="chat()">
      <div class="h-44 flex flex-col-reverse overflow-auto">
        <div id="room-messages">
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
        @focus="$store.inputFocused = true"
        @blur="$store.inputFocused = false"
        @keydown.enter="sendMessage"
        phx-hook="ChatInput"
      />
      <button @click="sendMessage">Send</button>
    </div>
    """
  end
end
