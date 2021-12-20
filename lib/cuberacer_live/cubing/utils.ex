defmodule CuberacerLive.Cubing.Utils do
  def generate_scramble do
    # TODO: Real scramble
    Ecto.UUID.generate()
  end
end
