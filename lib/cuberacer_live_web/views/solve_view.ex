defmodule CuberacerLiveWeb.SolveView do
  use CuberacerLiveWeb, :view
  import CuberacerLiveWeb.SharedUtils, only: [format_datetime: 1]
  import CuberacerLive.Sessions, only: [display_solve: 1]
end
