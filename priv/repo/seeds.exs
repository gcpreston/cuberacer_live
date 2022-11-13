# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     CuberacerLive.Repo.insert!(%CuberacerLive.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias CuberacerLive.Repo
alias CuberacerLive.Accounts.User

if not Repo.exists?(User) do
  Repo.insert!(
    %User{}
    |> User.registration_changeset(%{
      email: "testuser1@example.com",
      username: "testuser1",
      password: "password"
    })
  )
end
