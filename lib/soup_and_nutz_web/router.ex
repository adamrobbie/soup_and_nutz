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

  # Authentication pipelines
  pipeline :auth do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SoupAndNutzWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug SoupAndNutzWeb.Plugs.OptionalAuthenticate
  end

  # Authentication routes without CSRF protection (for login/register)
  pipeline :auth_no_csrf do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SoupAndNutzWeb.Layouts, :root}
    plug :put_secure_browser_headers
    plug SoupAndNutzWeb.Plugs.OptionalAuthenticate
  end

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SoupAndNutzWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug SoupAndNutzWeb.Plugs.Authenticate
  end

  pipeline :optional_auth do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SoupAndNutzWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug SoupAndNutzWeb.Plugs.OptionalAuthenticate
  end

  # Public routes (no authentication required)
  scope "/", SoupAndNutzWeb do
    pipe_through :optional_auth

    get "/", PageController, :home
  end

  # Authentication routes
  scope "/auth", SoupAndNutzWeb do
    pipe_through :auth

    get "/login", AuthController, :login
    get "/register", AuthController, :register
    delete "/logout", AuthController, :logout
  end

  # Authentication POST routes (without CSRF for now)
  scope "/auth", SoupAndNutzWeb do
    pipe_through :auth_no_csrf

    post "/login", AuthController, :login_post
    post "/register", AuthController, :register_post
  end

  # Protected routes (authentication required)
  scope "/", SoupAndNutzWeb do
    pipe_through :protected

    # User profile management
    get "/auth/profile", AuthController, :profile
    put "/auth/profile", AuthController, :profile_update
    get "/auth/change_password", AuthController, :change_password
    put "/auth/change_password", AuthController, :change_password_post

    # Financial data management (protected)
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

    live "/cash_flows", CashFlowLive.Index, :index
    live "/cash_flows/new", CashFlowLive.Index, :new
    live "/cash_flows/:id/edit", CashFlowLive.Index, :edit
    live "/cash_flows/:id", CashFlowLive.Show, :show
    live "/cash_flows/:id/show/edit", CashFlowLive.Show, :edit

    live "/financial_goals", FinancialGoalLive.Index, :index
    live "/financial_goals/new", FinancialGoalLive.Index, :new
    live "/financial_goals/:id/edit", FinancialGoalLive.Index, :edit
    live "/financial_goals/:id", FinancialGoalLive.Show, :show
    live "/financial_goals/:id/show/edit", FinancialGoalLive.Show, :edit

    # Budget and Debt Payoff Planning
    live "/budget", BudgetLive.Index, :index
    live "/budget-tracking", BudgetTrackingLive.Index, :index
    live "/debt-payoff", DebtPayoffLive.Index, :index

    # Advanced Analysis
    live "/cash-flow-forecast", CashFlowForecastLive.Index, :index
    live "/net-worth-projection", NetWorthProjectionLive.Index, :index

    # Remove these lines that reference undefined controllers
    # resources "/assets", AssetController
    # resources "/debt_obligations", DebtObligationController
  end

  # API routes
  scope "/", SoupAndNutzWeb do
    pipe_through :api
    get "/health", HealthController, :index
    get "/metrics", MetricsController, :index
  end

  # Fallback routes for unsupported methods
  scope "/", SoupAndNutzWeb do
    pipe_through :browser

    # Catch all unsupported methods for browser routes
    match :*, "/*path", Plugs.MethodNotAllowed, :index
  end

  scope "/", SoupAndNutzWeb do
    pipe_through :api

    # Catch all unsupported methods for API routes
    match :*, "/*path", Plugs.MethodNotAllowed, :index
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
