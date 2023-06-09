defmodule CuberacerLiveWeb.CoreComponents do
  use Phoenix.Component

  import CuberacerLiveWeb.SharedUtils, only: [format_datetime: 1]

  alias Phoenix.LiveView.JS

  @doc """
  Renders a live component inside a modal.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <.modal return_to={~p"/lobby"}>
        <.live_component
          module={CuberacerLiveWeb.SessionLive.FormComponent}
          id={@session.id || :new}
          title={@page_title}
          action={@live_action}
          return_to={~p"/lobby"}
          session: @session
        />
      </.modal>
  """

  attr :return_to, :string, default: nil
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div id="modal" class="phx-modal fade-in" phx-remove={hide_modal()}>
      <div
        id="modal-content"
        class="phx-modal-content fade-in-scale"
        phx-click-away={JS.dispatch("click", to: "#close")}
        phx-window-keydown={JS.dispatch("click", to: "#close")}
        phx-key="escape"
      >
        <%= if @return_to do %>
          <.link patch={@return_to} id="close" class="phx-modal-close">
            ✖
          </.link>
        <% else %>
          <a id="close" href="#" class="phx-modal-close" phx-click={hide_modal()}>✖</a>
        <% end %>

        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(to: "#modal", transition: "fade-out")
    |> JS.hide(to: "#modal-content", transition: "fade-out-scale")
  end

  slot :inner_block

  def table_header(assigns) do
    ~H"""
    <div class="bg-gray-50 sticky top-0">
      <div>
        <div class="border-y px-2 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
          <div class="inline-flex max-w-full">
            <span class="flex-1 truncate">
              <%= render_slot(@inner_block) %>
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  slot :inner_block

  def table_cell(assigns) do
    ~H"""
    <div class="border-b px-2 py-4 whitespace-nowrap">
      <div class="text-sm font-medium text-center text-gray-900">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  # Ensure that the safelist in tailwind.config.js is synchronized
  # with this list.
  @chat_username_colors [
    "red-600",
    "orange-500",
    "yellow-500",
    "emerald-600",
    "sky-500",
    "blue-600",
    "indigo-600",
    "fuchsia-600",
    "pink-600"
  ]

  attr :id, :string, required: false
  attr :room_message, :any, required: true, doc: "The Messaging.RoomMessage to display."
  attr :color_seed, :any, required: true

  def chat_message(assigns) do
    assigns =
      if assigns[:id] do
        assigns
      else
        assign(assigns, :id, "room_messages-#{assigns.room_message.id}")
      end

    ~H"""
    <div id={@id} class="px-2 t_room-message" title={format_datetime(@room_message.inserted_at)}>
      <span class={"font-medium #{user_chat_color(@room_message.user_id, @color_seed)} t_room_messages-username"}>
        <%= "#{@room_message.user.username}: " %>
      </span>
      <span class="t_room_messages-content">
        <%= @room_message.message %>
      </span>
    </div>
    """
  end

  defp user_chat_color(user_id, color_seed) do
    options = @chat_username_colors
    color = Enum.at(options, :erlang.phash2({user_id, color_seed}, length(options)))

    "text-#{color}"
  end
end
