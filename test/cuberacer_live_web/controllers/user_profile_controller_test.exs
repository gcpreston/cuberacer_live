defmodule CuberacerLiveWeb.UserProfileControllerTest do
  use CuberacerLiveWeb.ConnCase, async: true

  import CuberacerLive.AccountsFixtures
  import CuberacerLive.SessionsFixtures

  alias CuberacerLive.CountryUtils

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/:id" do
    test "displays a different user's profile with profile data", %{conn: conn, user: user} do
      # 20.5 years ago
      birthday = Date.add(Date.utc_today(), -7480)

      other_user =
        user_fixture(
          bio: "some test bio",
          wca_id: "2020ABCD01",
          country: "US",
          birthday: birthday
        )

      _session1 = session_fixture(name: "session not on profile")
      session2 = session_fixture(name: "session on profile", puzzle_type: :"4x4")
      round = round_fixture(session: session2)
      _solve = solve_fixture(round_id: round.id, user_id: other_user.id)

      conn =
        conn
        |> log_in_user(user)
        |> get(Routes.user_profile_path(conn, :show, other_user.id))

      html = html_response(conn, 200)

      html
      |> assert_html("#profile-username", other_user.username)
      |> assert_html("#profile-bio", other_user.bio)
      |> assert_html(
        ~s(a#profile-wca-link[href="https://www.worldcubeassociation.org/persons/#{other_user.wca_id}")
      )
      |> assert_html(
        "#profile-country",
        "#{CountryUtils.country_name_from_code(other_user.country)} #{CountryUtils.to_flag_emoji(other_user.country)}"
      )
      |> assert_html("#profile-age", "Age 20")
      |> assert_html(
        "#profile-join-date",
        "Joined #{Calendar.strftime(Date.utc_today(), "%B %Y")}"
      )
      |> refute_html("#profile-edit")

      assert html =~ "Sessions"
      refute html =~ "session not on profile"
      assert html =~ "session on profile"
      assert html =~ "4x4"
    end

    test "shows unlisted sessions on your own profile", %{conn: conn, user: user} do
      _session = session_fixture(name: "unlisted session", unlisted?: true, host_id: user.id)

      conn =
        conn
        |> log_in_user(user)
        |> get(Routes.user_profile_path(conn, :show, user.id))

      html = html_response(conn, 200)

      assert html =~ "unlisted session"
      assert html =~ "fas fa-lock"
    end

    test "does not show unlisted sessions on someone else's profile", %{conn: conn, user: user1} do
      user2 = user_fixture()
      session = session_fixture(name: "unlisted session", unlisted?: true, host_id: user2.id)
      round = round_fixture(session: session)
      _user1_solve = solve_fixture(round_id: round.id, user_id: user1.id)

      conn =
        conn
        |> log_in_user(user1)
        |> get(Routes.user_profile_path(conn, :show, user2.id))

      html = html_response(conn, 200)

      refute html =~ "unlisted session"
    end

    test "shows Edit profile button on your own profile", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> get(Routes.user_profile_path(conn, :show, user.id))

      html = html_response(conn, 200)
      assert_html(html, "#profile-edit", "Edit profile")
    end

    test "does not show profile data not provided", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> get(Routes.user_profile_path(conn, :show, user.id))

      html = html_response(conn, 200)

      html
      |> assert_html("#profile-username", user.username)
      |> refute_html("#profile-bio")
      |> refute_html("#profile-wca-link")
      |> refute_html("#profile-country")
      |> refute_html("#profile-age")
      |> assert_html(
        "#profile-join-date",
        "Joined #{Calendar.strftime(Date.utc_today(), "%B %Y")}"
      )

      assert html =~ "Sessions"
    end

    test "redirects if not logged in", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_profile_path(conn, :show, user.id))
      assert redirected_to(conn) == "/login"
    end
  end
end
