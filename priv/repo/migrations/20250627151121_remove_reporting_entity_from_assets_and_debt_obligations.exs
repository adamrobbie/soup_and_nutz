defmodule SoupAndNutz.Repo.Migrations.RemoveReportingEntityFromAssetsAndDebtObligations do
  use Ecto.Migration

  def change do
    # Remove reporting_entity column and index from assets
    drop index(:assets, [:reporting_entity])
    alter table(:assets) do
      remove :reporting_entity
    end

    # Remove reporting_entity column and index from debt_obligations
    drop index(:debt_obligations, [:reporting_entity])
    alter table(:debt_obligations) do
      remove :reporting_entity
    end
  end
end
