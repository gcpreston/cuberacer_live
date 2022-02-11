defmodule CuberacerLiveWeb.SharedComponents do
  use Phoenix.Component
  alias CuberacerLiveWeb.Router.Helpers, as: Routes

  @doc """
  A country flag SVG. Can be wrapped with styles.
  """
  def flag(assigns) do
    ~H"""
    <img
      class={@class}}
      src={Routes.static_path(CuberacerLiveWeb.Endpoint, "/images/flags/#{String.downcase(@code)}.svg")}
      alt={String.upcase(@code)}
    >
    """
  end
end
