defmodule SoupAndNutz.Repo do
  use Ecto.Repo,
    otp_app: :soup_and_nutz,
    adapter: Ecto.Adapters.Postgres
end
