defmodule CuberacerLiveWeb.UserProfileView do
  use CuberacerLiveWeb, :view

  import CuberacerLiveWeb.SharedUtils, only: [format_datetime: 1]

  alias CuberacerLive.CountryUtils
  alias CuberacerLive.Accounts

  defp session_block(assigns) do
    ~H"""
    <%= link to: Routes.session_path(CuberacerLiveWeb.Endpoint, :show, @session.id) do %>
      <div class="relative p-4 rounded-lg shadow-sm border bg-white transition-all hover:bg-gray-50 hover:shadow-md">
        <%= if @session.unlisted? do %>
          <span class="absolute top-2 right-2"><i class="fas fa-lock"></i></span>
        <% end %>

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
