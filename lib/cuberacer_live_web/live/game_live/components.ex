defmodule CuberacerLiveWeb.GameLive.Components do
  use CuberacerLiveWeb, :component

  alias CuberacerLive.Sessions

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

  def timer(assigns) do
    ~H"""
    <div
      id="timer"
      x-init={
        if @current_solve, do: "presetTime(#{@current_solve.time})", else: "hasCurrentSolve = false"
      }
    >
      <span id="time" x-text="formattedTime" x-bind:class="timeColor"></span>
    </div>
    """
  end

  def keyboard_input(assigns) do
    ~H"""
    <.form :let={f} id="keyboard-input" for={%{}} phx-submit="keyboard-submit">
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

  attr :room_messages_stream, :any, required: true
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
        <div id="room-messages" phx-update="stream" class="divide-y">
          <%= for {id, room_message} <- @room_messages_stream do %>
            <.chat_message
              id={id}
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

  attr :participant_data, :any, required: true

  attr :rounds, :list,
    required: true,
    doc: "A list of all rounds in the session. Must have solved preloaded."

  def times_table(assigns) do
    # Taps into 'room' Alpine data
    ~H"""
    <div class="flex flex-row justify-start" id="times-table" x-init="calibratePagination()">
      <div
        :for={{{_user_id, entry}, i} <- Enum.with_index(@participant_data)}
        class="flex-none js_user-column"
        x-bind:class={"{ 'hidden': !isColShown(#{i}) }"}
      >
        <.live_component
          id={"participant-component-#{entry.user.id}"}
          module={CuberacerLiveWeb.GameLive.ParticipantComponent}
          participant_data_entry={entry}
          rounds={@rounds}
        />
      </div>

      <div class="w-24 flex-1">
        <.table_header />

        <div class="bg-white" x-show="bottomBarShow">
          <div :for={_round <- @rounds}>
            <.table_cell>&nbsp</.table_cell>
          </div>
        </div>
      </div>
    </div>
    """
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

  attr :num_present_users, :integer, required: true

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
            <%= @num_present_users %> <%= Inflex.inflect("participant", @num_present_users) %>
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
