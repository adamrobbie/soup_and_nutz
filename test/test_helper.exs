ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(SoupAndNutz.Repo, :manual)

# Require all support files
for file <- Path.wildcard("#{__DIR__}/support/**/*.ex*"), do: Code.require_file(file)
