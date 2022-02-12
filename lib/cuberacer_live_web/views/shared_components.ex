defmodule CuberacerLiveWeb.SharedComponents do
  use Phoenix.Component
  use CuberacerLiveWeb, :view

  import Phoenix.HTML.Link, only: [link: 2]

  alias CuberacerLiveWeb
  alias CuberacerLiveWeb.Endpoint
  alias CuberacerLive.Sessions
  alias CuberacerLive.Sessions.Round
  alias CuberacerLive.Accounts.User

  def rounds_table(assigns) do
    ~H"""
    <table class="w-full border-separate [border-spacing:0]">
      <thead class="bg-gray-50 sticky top-0">
        <tr>
          <%= if @include_scramble do %>
            <th scope="col" class="border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Scramble
            </th>
          <% end %>
          <%= for user <- @users do %>
            <th scope="col" class="border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              <%= if @include_links do %>
                <%= link user.username, to: Routes.user_profile_path(Endpoint, :show, user.id) %>
              <% else %>
                <%= user.username %>
              <% end %>
            </th>
          <% end %>
        </tr>
      </thead>
      <tbody id="times-table-body" class="bg-white" phx-update="prepend">
        <%= for round <- @rounds do %>
          <tr id={"round-#{round.id}"} class="t_round-row">

            <%= if @include_scramble do %>
              <td class="border-b px-6 py-4">
                <div class="ml-4">
                  <div class="text-sm font-medium text-gray-900">
                    <%= if @include_links do %>
                      <%= link round.scramble, to: Routes.round_path(Endpoint, :show, round.id) %>
                    <% else %>
                      <%= round.scramble %>
                    <% end %>
                  </div>
                </div>
              </td>
            <% end %>

            <%= for user <- @users do %>
              <.solve_cell user={user} round={round} include_link={@include_links} />
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  defp solve_cell(assigns) do
    solve = user_solve_for_round(assigns.user, assigns.round)
    text = Sessions.display_solve(solve)

    ~H"""
    <td id={"round-#{@round.id}-solve-user-#{@user.id}"} class="border-b px-6 py-4 whitespace-nowrap">
      <div class="ml-4">
        <div class="text-sm font-medium text-gray-900">
          <%= if @include_link && solve do %>
            <%= link text, to: Routes.solve_path(Endpoint, :show, solve.id) %>
          <% else %>
            <%= text %>
          <% end %>
        </div>
      </div>
    </td>
    """
  end

  defp user_solve_for_round(%User{} = user, %Round{} = round) do
    Enum.find(round.solves, fn solve -> solve.user_id == user.id end)
  end
end
