defmodule CuberacerLiveWeb.UserProfileView do
  use CuberacerLiveWeb, :view

  import CuberacerLiveWeb.SharedUtils, only: [format_datetime: 1]

  alias CuberacerLive.Accounts
  alias CuberacerLive.Sessions

  defp session_block(assigns) do
    ~H"""
    <%= link to: Routes.session_path(CuberacerLiveWeb.Endpoint, :show, @session.id) do %>
      <div class="p-4 rounded-lg shadow-sm border bg-white transition-all hover:bg-gray-50 hover:shadow-md">
        <div>
          <span class="font-medium"><%= @session.name %></span> | <span><%= @session.puzzle_type %></span>
        </div>
        <div>
          <span class="text-gray-500 italic text-sm"><%= format_datetime(@session.inserted_at) %></span>
        </div>
      </div>
    <% end %>
    """
  end
end
