defmodule CuberacerLive.ParticipantDataEntry do
  alias CuberacerLive.Accounts.User

  @type time_entry_method() :: :timer | :keyboard

  defstruct user: nil, meta: %{solving: false, time_entry: :timer, spectating: false}

  @spec new(%User{}) :: %__MODULE__{}
  def new(%User{} = user) do
    %__MODULE__{user: user}
  end

  @spec get_solving(%__MODULE__{}) :: boolean()
  def get_solving(entry) do
    entry.meta.solving
  end

  @spec set_solving(%__MODULE__{}, boolean()) :: %__MODULE__{}
  def set_solving(entry, solving) do
    put_in(entry.meta.solving, solving)
  end

  @spec get_time_entry(%__MODULE__{}) :: time_entry_method()
  def get_time_entry(entry) do
    entry.meta.time_entry
  end

  @spec set_time_entry(%__MODULE__{}, time_entry_method()) :: %__MODULE__{}
  def set_time_entry(entry, method) do
    put_in(entry.meta.time_entry, method)
  end

  @spec get_spectating(%__MODULE__{}) :: boolean()
  def get_spectating(entry) do
    entry.meta.spectating
  end

  @spec set_spectating(%__MODULE__{}, boolean()) :: %__MODULE__{}
  def set_spectating(entry, spectating) do
    put_in(entry.meta.spectating, spectating)
  end
end
