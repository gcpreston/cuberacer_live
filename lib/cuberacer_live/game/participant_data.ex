defmodule CuberacerLive.ParticipantData do
  alias CuberacerLive.ParticipantDataEntry
  alias CuberacerLive.Accounts.User

  @type participant_data :: %{non_neg_integer() => %ParticipantDataEntry{}}

  @spec new([%User{}]) :: participant_data()
  def new(users) when is_list(users) do
    Enum.reduce(users, %{}, fn user, acc ->
      Map.put(acc, user.id, ParticipantDataEntry.new(user))
    end)
  end

  @doc """
  Retrieve the `ParticipantDataEntry` for a given user.
  """
  @spec get_entry(participant_data(), %User{}) :: %ParticipantDataEntry{}
  def get_entry(data, %User{id: user_id}) do
    Map.get(data, user_id)
  end

  @doc """
  Set a `ParticipantDataEntry`.
  """
  @spec set_entry(participant_data(), %ParticipantDataEntry{}) :: participant_data()
  def set_entry(data, entry) do
    Map.put(data, entry.user.id, entry)
  end

  @doc """
  Get entries for users currently participating, not spectating.
  """
  @spec non_spectators(participant_data()) :: participant_data()
  def non_spectators(data) do
    Enum.filter(data, fn {user_id, entry} -> !ParticipantDataEntry.get_spectating(entry) end)
  end

  @doc """
  Get entries for users currently spectating.
  """
  @spec spectators(participant_data()) :: participant_data()
  def spectators(data) do
    Enum.filter(data, fn {user_id, entry} -> ParticipantDataEntry.get_spectating(entry) end)
  end
end
