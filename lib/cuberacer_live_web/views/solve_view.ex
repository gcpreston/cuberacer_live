defmodule CuberacerLiveWeb.SolveView do
  use CuberacerLiveWeb, :view
  import CuberacerLiveWeb.SharedUtils, only: [format_datetime: 1]
  import CuberacerLive.Sessions, only: [display_solve: 1, session_locator: 1]
end
