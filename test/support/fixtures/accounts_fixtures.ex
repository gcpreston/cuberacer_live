defmodule CuberacerLive.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `CuberacerLive.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  def unique_email_and_username do
    username = "user#{System.unique_integer()}"
    email = "#{username}@example.com"
    {email, username}
  end

  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    {email, username} = unique_email_and_username()

    Enum.into(attrs, %{
      email: email,
      username: username,
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> CuberacerLive.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
