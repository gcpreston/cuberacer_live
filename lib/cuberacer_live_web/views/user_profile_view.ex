defmodule CuberacerLiveWeb.UserProfileView do
  use CuberacerLiveWeb, :view

  alias CuberacerLive.Accounts
  alias CuberacerLive.Sessions

  defp format_date(date) do
    Enum.join([date.year, date.month, date.day], "/")
  end

  defp session_block(assigns) do
    ~H"""
    <div class="p-4 rounded-lg shadow-sm border bg-white transition-all hover:bg-gray-50 hover:shadow-md">
      <div>
        <span class="font-medium"><%= @session.name %></span> | <span><%= @session.cube_type.name %></span>
      </div>
      <div>
        <span class="text-gray-500 italic text-sm"><%= format_date(@session.inserted_at) %></span>
      </div>
    </div>
    """
  end
end
