defmodule CuberacerLive.ParticipantDataEntry do
  alias CuberacerLive.Accounts.User

  @type time_entry_method() :: :timer | :keyboard

  @type t :: %__MODULE__{
          user: User.t(),
          meta: %{
            solving: boolean(),
            time_entry: time_entry_method()
          }
        }

  defstruct user: nil, meta: %{solving: false, time_entry: :timer}

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
end
