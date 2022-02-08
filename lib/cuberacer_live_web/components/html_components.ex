defmodule CuberacerLiveWeb.HTMLComponents do
  use Phoenix.Component
  alias CuberacerLiveWeb.Router.Helpers, as: Routes

  def flag(assigns) do
    ~H"""
    <img
      class={"h-#{@height}"}
      src={Routes.static_path(CuberacerLiveWeb.Endpoint, "/images/flags/#{String.downcase(@code)}.svg")}
      alt={String.upcase(@code)}
    >
    """
  end
end
