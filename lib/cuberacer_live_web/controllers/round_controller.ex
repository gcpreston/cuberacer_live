defmodule CuberacerLiveWeb.RoundController do
  use CuberacerLiveWeb, :controller

  alias CuberacerLive.Sessions

  def show(conn, %{"id" => round_id}) do
    round = Sessions.get_loaded_round!(round_id)
    render(conn, "show.html", round: round)
  end
end
