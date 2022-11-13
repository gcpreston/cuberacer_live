defmodule CuberacerLiveWeb.UserSettingsControllerTest do
  use CuberacerLiveWeb.ConnCase, async: true

  alias CuberacerLive.Accounts
  import CuberacerLive.AccountsFixtures

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, ~p"/users/settings")
      response = html_response(conn, 200)
      assert response =~ "Settings</h1>"
    end

    test "renders user unconfirmed status", %{conn: conn} do
      conn = get(conn, ~p"/users/settings")
      response = html_response(conn, 200)
      assert response =~ "Unconfirmed"
      refute response =~ "Confirmed"
      assert response =~ "Resend confirmation email</button>"
    end

    test "renders user confirmed status", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      conn =
        post(conn, ~p"/users/confirm/#{token}")
        |> get(~p"/users/settings")

      response = html_response(conn, 200)
      assert response =~ "Confirmed"
      refute response =~ "Unconfirmed"
      refute response =~ "Resend confirmation email</button>"
    end

    test "renders country name dropdown", %{conn: conn} do
      conn = get(conn, ~p"/users/settings")
      html = html_response(conn, 200)

      html
      |> assert_html("select[name='user[country]']", count: 1)
      |> assert_html("select option[value='US']", text: "United States")
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, ~p"/users/settings")
      assert redirected_to(conn) == ~p"/login"
    end
  end

  describe "PUT /users/settings (change profile form)" do
    test "updates the user profile", %{conn: conn, user: user} do
      conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_profile",
          "user" => %{
            "bio" => "some new bio",
            "wca_id" => "2037TEST04",
            "country" => "GB",
            "birthday" => "1996-12-21"
          }
        })

      assert redirected_to(conn) == ~p"/users/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Profile updated successfully"

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.bio == "some new bio"
      assert updated_user.wca_id == "2037TEST04"
      assert updated_user.country == "GB"
      assert updated_user.birthday == ~D[1996-12-21]
    end

    test "does not update if bio is too long", %{conn: conn, user: user} do
      conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_profile",
          "user" => %{
            "bio" => String.duplicate("some new bio", 100),
            "wca_id" => "2037TEST04",
            "country" => "GB",
            "birthday" => "1996-12-21"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "Settings</h1>"
      assert response =~ "should be at most 500 character(s)"
      assert Accounts.get_user!(user.id) == user
    end

    test "blank country removes country", %{conn: conn, user: user} do
      conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_profile",
          "user" => %{
            "country" => ""
          }
        })

      assert redirected_to(conn) == ~p"/users/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Profile updated successfully"

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.country == nil
    end
  end

  describe "PUT /users/settings (change password form)" do
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_password",
          "current_password" => valid_user_password(),
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == ~p"/users/settings"
      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_password",
          "current_password" => "invalid",
          "user" => %{
            "password" => "short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "Settings</h1>"
      assert response =~ "should be at least 6 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /users/settings (change email form)" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user} do
      conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_email",
          "current_password" => valid_user_password(),
          "user" => %{"email" => unique_user_email()}
        })

      assert redirected_to(conn) == ~p"/users/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "A link to confirm your email"
      assert Accounts.get_user_by_email(user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_email",
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /users/settings/confirm_email/:token" do
    setup %{user: user} do
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      conn = get(conn, ~p"/users/settings/confirm_email/#{token}")
      assert redirected_to(conn) == ~p"/users/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Email changed successfully"
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      conn = get(conn, ~p"/users/settings/confirm_email/#{token}")
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, ~p"/users/settings/confirm_email/oops")
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"

      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, ~p"/users/settings/confirm_email/#{token}")
      assert redirected_to(conn) == ~p"/login"
    end
  end
end
