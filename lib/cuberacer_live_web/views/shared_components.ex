defmodule CuberacerLiveWeb.SharedComponents do
  use CuberacerLiveWeb, :component

  import CuberacerLiveWeb.SharedUtils, only: [format_datetime: 1]

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
    options = chat_username_colors()
    color = Enum.at(options, :erlang.phash2({user_id, color_seed}, length(options)))

    "text-#{color}"
  end

  defp chat_username_colors do
    config = Application.get_env(:cuberacer_live, :frontend_config)
    config["chatUsernameColors"]
  end
end
