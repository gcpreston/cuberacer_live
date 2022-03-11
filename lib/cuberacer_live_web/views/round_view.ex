defmodule CuberacerLiveWeb.RoundView do
  use CuberacerLiveWeb, :view

  import CuberacerLiveWeb.SharedUtils, only: [format_datetime: 1]
  import CuberacerLiveWeb.SharedComponents, only: [session_link: 1]
  import CuberacerLive.Sessions, only: [display_solve: 1, session_locator: 1]

  def solves_table(assigns) do
    ~H"""
    <%= if length(@solves) == 0 do %>
      <div class="italic text-gray-700">No solves</div>
    <% else %>
      <div class="border rounded-md shadow">
        <table class="w-full divide-y">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                User
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Time
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y">
            <%= for solve <- @solves do %>
              <tr>
                <td class="px-6 py-4 whitespace-nowrap">
                  <%= link solve.user.username, to: Routes.user_profile_path(CuberacerLiveWeb.Endpoint, :show, solve.user_id) %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <%= link display_solve(solve), to: Routes.solve_path(CuberacerLiveWeb.Endpoint, :show, solve.id) %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    <% end %>
    """
  end
end
