defmodule CuberacerLiveWeb.SolveController do
  use CuberacerLiveWeb, :controller

  alias CuberacerLive.Sessions

  def show(conn, %{"id" => solve_id}) do
    solve = Sessions.get_loaded_solve!(solve_id)
    render(conn, "show.html", solve: solve)
  end
end
