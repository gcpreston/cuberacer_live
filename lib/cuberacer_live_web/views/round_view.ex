defmodule CuberacerLiveWeb.RoundView do
  use CuberacerLiveWeb, :view

  import CuberacerLiveWeb.SharedUtils, only: [format_datetime: 1]
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
                  <.link href={~p"/users/#{solve.user_id}"}>
                    <%= solve.user.username %>
                  </.link>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <.link href={~p"/solves/#{solve.id}"}>
                    <%= display_solve(solve) %>
                  </.link>
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
