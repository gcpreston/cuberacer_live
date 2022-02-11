defmodule CuberacerLiveWeb.SharedComponents do
  use Phoenix.Component

  @doc """
  TailwindCSS classes for input elements.
  """
  def input_classes do
    "block w-full rounded-md mt-0.5 px-2 py-0.5 border border-gray-300 bg-gray-100 focus:bg-white"
  end

  def input_classes(extras) do
    "#{input_classes()} #{extras}"
  end

  @doc """
  TailwindCSS classes for green buttons.
  """
  def success_button_classes() do
    "rounded-lg bg-green-400 hover:bg-green-300 active:bg-green-400 border border-green-500 w-full transition-all"
  end

  def success_button_classes(extras) do
    "#{success_button_classes()} #{extras}"
  end
end
