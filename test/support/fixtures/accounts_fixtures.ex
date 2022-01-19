defmodule CuberacerLive.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `CuberacerLive.Accounts` context.
  """

  defp unique_suffix, do: String.replace("#{System.unique_integer()}", "-", "_")

  def unique_user_email, do: "user#{unique_suffix()}@example.com"

  def unique_email_and_username do
    username = "user#{unique_suffix()}"
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
