defmodule CuberacerLiveWeb.Components do
  use Phoenix.Component

  import CuberacerLiveWeb.SharedUtils, only: [format_datetime: 1]

  alias Phoenix.LiveView.JS
  alias CuberacerLiveWeb.Router.Helpers, as: Routes
  alias CuberacerLive.Sessions

  @doc """
  Renders a live component inside a modal.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <.modal return_to={Routes.session_index_path(@socket, :index)}>
        <.live_component
          module={CuberacerLiveWeb.SessionLive.FormComponent}
          id={@session.id || :new}
          title={@page_title}
          action={@live_action}
          return_to={Routes.session_index_path(@socket, :index)}
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
          <.link patch={@return_to} id="close" class="phx-modal-close" phx_click={hide_modal()}>
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

  attr :room_message, :any, required: true, doc: "The Messaging.RoomMessage to display."
  attr :color_seed, :any, required: true

  def chat_message(assigns) do
    ~H"""
    <div
      id={"room-message-#{@room_message.id}"}
      class="px-2 t_room-message"
      title={format_datetime(@room_message.inserted_at)}
    >
      <span class={"font-medium #{user_chat_color(@room_message.user_id, @color_seed)} t_room-message-username"}>
        <%= "#{@room_message.user.username}: " %>
      </span>
      <span class="t_room-message-content">
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

  attr :session, :any, required: true, doc: "The Sessions.Session to link to."
  slot :inner_block, requied: true

  def session_link(assigns) do
    ~H"""
    <.link href={
      Routes.session_path(CuberacerLiveWeb.Endpoint, :show, Sessions.session_locator(assigns.session))
    }>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end
end
