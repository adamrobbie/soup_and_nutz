import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :soup_and_nutz, SoupAndNutz.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "soup_and_nutz_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :soup_and_nutz, SoupAndNutzWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "your-secret-key-base-here-for-testing-only-do-not-use-in-production",
  server: true

# In test we don't send emails
config :soup_and_nutz, SoupAndNutz.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Configure Wallaby for E2E testing
config :wallaby,
  otp_app: :soup_and_nutz,
  base_url: "http://localhost:4002",
  screenshot_dir: "test/screenshots",
  screenshot_on_failure: true,
  chromedriver: [
    headless: true,
    capabilities: %{
      chromeOptions: %{
        args: [
          "--headless=new",
          "--disable-gpu",
          "--no-sandbox",
          "--disable-dev-shm-usage",
          "--window-size=1920,1080",
          "--disable-software-rasterizer",
          "--disable-extensions"
        ]
      }
    }
  ]
