defmodule CuberacerLiveWeb.SessionView do
  use CuberacerLiveWeb, :view

  import CuberacerLiveWeb.SharedUtils, only: [format_datetime: 1]
  import CuberacerLiveWeb.SharedComponents, only: [rounds_table: 1]

  alias CuberacerLive.Sessions.{Session, Round}

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

  defp messages_block(assigns) do
    ~H"""
    <%= if length(@messages) == 0 do %>
      <div class="italic text-gray-700">No messages</div>
    <% else %>
      <div class="flex flex-col">
        <div class="divide-y">
          <%= for message <- @messages do %>
            <div title={format_datetime(message.inserted_at)}>
              <%= CuberacerLive.Messaging.display_room_message(message) %>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end
end
