defmodule SoupAndNutz.Repo.Migrations.RemoveReportingEntityFromNetWorthSnapshots do
  use Ecto.Migration

  def up do
    # Remove reporting_entity column from net_worth_snapshots
    # Note: The index may not exist, so we'll just remove the column
    alter table(:net_worth_snapshots) do
      remove :reporting_entity
    end
  end

  def down do
    # Add back the reporting_entity column if needed
    alter table(:net_worth_snapshots) do
      add :reporting_entity, :string
    end
  end
end
