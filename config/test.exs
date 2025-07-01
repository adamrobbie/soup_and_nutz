import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :soup_and_nutz, SoupAndNutz.Repo,
  url: "postgres://postgres:postgres@localhost:5434/soup_and_nutz_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 20,
  queue_target: 5000,
  queue_interval: 10_000

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :soup_and_nutz, SoupAndNutzWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "your-secret-key-base-here-for-testing-only-do-not-use-in-production",
  server: true

# In test we don't send emails
config :soup_and_nutz, SoupAndNutz.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Optimize test performance
config :ex_unit,
  capture_log: false,
  trace: false,
  max_cases: 16,
  timeout: 30_000

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Disable embedding service during tests to avoid vector type issues
config :soup_and_nutz, :enable_embeddings, false

# Optimize database for tests
config :soup_and_nutz, SoupAndNutz.Repo,
  migration_lock: false,
  show_sensitive_data_on_connection_error: false

# Mock OpenAI service for testing
config :soup_and_nutz, :openai_service, %{
  process_natural_language_input: fn _prompt, _user_id ->
    {:ok, %{
      "type" => "asset",
      "data" => %{
        "asset_name" => "Test Asset",
        "fair_value" => "10000"
      },
      "confidence" => 0.95,
      "missing_fields" => [],
      "suggestions" => []
    }}
  end,
  generate_embedding: fn _text ->
    {:ok, [0.1, 0.2, 0.3, 0.4, 0.5]}
  end
}
