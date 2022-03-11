defmodule CuberacerLive.Hashids do
  def new do
    Application.fetch_env!(:cuberacer_live, :hashids_config)
    |> Hashids.new()
  end
end
