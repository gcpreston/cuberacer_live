defmodule CuberacerLiveWeb.SessionView do
  use CuberacerLiveWeb, :view

  import CuberacerLiveWeb.SharedUtils, only: [format_datetime: 1]

  alias CuberacerLive.Sessions
  alias CuberacerLive.Sessions.{Session, Round}
  alias CuberacerLive.Accounts.User

  # Fetch all users who participated in the session. Expects a Session
  # to be passed, at least loaded through solves.
  defp participants(%Session{rounds: rounds}) do
    Enum.reduce(
      rounds,
      MapSet.new(),
      fn round, users -> MapSet.union(round |> round_users() |> MapSet.new(), users) end
    )
  end

  defp round_users(%Round{solves: solves}) do
    Enum.map(solves, & &1.user)
  end

  defp rounds_table(assigns) do
    ~H"""
    <table class="w-full border-separate [border-spacing:0]">
      <thead class="bg-gray-50 sticky top-0">
        <tr>
          <th
            scope="col"
            class="border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
          >
            Scramble
          </th>

          <%= for user <- @users do %>
            <th
              scope="col"
              class="border-y px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
            >
              <.link href={~p"/users/#{user.id}"}>
                <%= user.username %>
              </.link>
            </th>
          <% end %>
        </tr>
      </thead>
      <tbody id="times-table-body" class="bg-white">
        <%= for round <- @rounds do %>
          <tr id={"round-#{round.id}"} class="t_round-row">
            <td class="border-b px-6 py-4">
              <div class="ml-4">
                <div class="text-sm font-medium text-gray-900">
                  <.link href={~p"/rounds/#{round.id}"}>
                    <%= round.scramble %>
                  </.link>
                </div>
              </div>
            </td>

            <%= for user <- @users do %>
              <.solve_cell user={user} round={round} />
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  defp solve_cell(assigns) do
    assigns = assign(assigns, :solve, user_solve_for_round(assigns.user, assigns.round))
    assigns = assign(assigns, :text, Sessions.display_solve(assigns.solve))

    ~H"""
    <td id={"round-#{@round.id}-solve-user-#{@user.id}"} class="border-b px-6 py-4 whitespace-nowrap">
      <div class="ml-4">
        <div class="text-sm font-medium text-gray-900">
          <%= if @solve do %>
            <.link href={~p"/solves/#{@solve.id}"}>
              <%= @text %>
            </.link>
          <% else %>
            <%= @text %>
          <% end %>
        </div>
      </div>
    </td>
    """
  end

  defp user_solve_for_round(%User{} = user, %Round{} = round) do
    Enum.find(round.solves, fn solve -> solve.user_id == user.id end)
  end

  attr :messages, :list, required: true
  attr :color_seed, :any, required: true

  defp messages_block(assigns) do
    ~H"""
    <%= if length(@messages) == 0 do %>
      <div class="italic text-gray-700">No messages</div>
    <% else %>
      <div class="flex flex-col">
        <div class="divide-y">
          <%= for message <- @messages do %>
            <div title={format_datetime(message.inserted_at)}>
              <.chat_message
                room_message={CuberacerLive.Repo.preload(message, :user)}
                color_seed={@color_seed}
              />
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end
end
