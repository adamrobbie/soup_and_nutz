defmodule SoupAndNutz.Repo.Migrations.RemoveReportingEntityFromCashFlows do
  use Ecto.Migration

  def up do
    # Remove reporting_entity column from cash_flows
    # Note: The index may not exist, so we'll just remove the column
    alter table(:cash_flows) do
      remove :reporting_entity
    end
  end

  def down do
    # Add back the reporting_entity column if needed
    alter table(:cash_flows) do
      add :reporting_entity, :string
    end
  end
end
