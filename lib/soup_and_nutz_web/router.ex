defmodule SoupAndNutzWeb.Router do
  use SoupAndNutzWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SoupAndNutzWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SoupAndNutzWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/assets", AssetLive.Index, :index
    live "/assets/new", AssetLive.Index, :new
    live "/assets/:id/edit", AssetLive.Index, :edit
    live "/assets/:id", AssetLive.Show, :show
    live "/assets/:id/show/edit", AssetLive.Show, :edit

    live "/debt_obligations", DebtObligationLive.Index, :index
    live "/debt_obligations/new", DebtObligationLive.Index, :new
    live "/debt_obligations/:id/edit", DebtObligationLive.Index, :edit
    live "/debt_obligations/:id", DebtObligationLive.Show, :show
    live "/debt_obligations/:id/show/edit", DebtObligationLive.Show, :edit
  end

  # Other scopes may use custom stacks.
  # scope "/api", SoupAndNutzWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:soup_and_nutz, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SoupAndNutzWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
