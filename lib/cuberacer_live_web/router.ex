defmodule CuberacerLiveWeb.Router do
  use CuberacerLiveWeb, :router

  import CuberacerLiveWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CuberacerLiveWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :browser_with_navbar do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CuberacerLiveWeb.LayoutView, :root_with_navbar}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", CuberacerLiveWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CuberacerLiveWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", CuberacerLiveWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end

  scope "/", CuberacerLiveWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/", PageController, :index

    get "/signup", UserRegistrationController, :new
    post "/signup", UserRegistrationController, :create
    get "/login", UserSessionController, :new
    post "/login", UserSessionController, :create

    get "/reset_password", UserResetPasswordController, :new
    post "/reset_password", UserResetPasswordController, :create
    get "/reset_password/:token", UserResetPasswordController, :edit
    put "/reset_password/:token", UserResetPasswordController, :update
  end

  ## Main application routes

  scope "/", CuberacerLiveWeb do
    pipe_through [:browser_with_navbar, :require_authenticated_user]

    live "/lobby", LobbyLive, :index
    live "/lobby/new", LobbyLive, :new
    live "/lobby/join/:id", LobbyLive, :join
    live "/rooms/:id", RoomLive, :show

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    get "/users/:id", UserProfileController, :show

    get "/sessions/:id", SessionController, :show
    get "/rounds/:id", RoundController, :show
    get "/solves/:id", SolveController, :show
  end
end
