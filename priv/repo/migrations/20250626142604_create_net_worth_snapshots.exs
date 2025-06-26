defmodule SoupAndNutz.Repo.Migrations.CreateNetWorthSnapshots do
  use Ecto.Migration

  def change do
    create table(:net_worth_snapshots) do
      add :snapshot_date, :date, null: false
      add :reporting_entity, :string, null: false
      add :reporting_period, :string, null: false
      add :currency_code, :string, null: false, default: "USD"

      # Net worth components
      add :total_assets, :decimal, precision: 15, scale: 2, null: false
      add :total_liabilities, :decimal, precision: 15, scale: 2, null: false
      add :net_worth, :decimal, precision: 15, scale: 2, null: false

      # Cash flow integration
      add :monthly_income, :decimal, precision: 15, scale: 2
      add :monthly_expenses, :decimal, precision: 15, scale: 2
      add :net_monthly_cash_flow, :decimal, precision: 15, scale: 2
      add :savings_rate, :decimal, precision: 5, scale: 2

      # Financial health metrics
      add :debt_to_asset_ratio, :decimal, precision: 5, scale: 4
      add :debt_to_income_ratio, :decimal, precision: 5, scale: 2
      add :liquidity_ratio, :decimal, precision: 8, scale: 2
      add :emergency_fund_ratio, :decimal, precision: 8, scale: 2

      # Risk and stability scores
      add :risk_score, :decimal, precision: 3, scale: 1
      add :financial_stability_score, :decimal, precision: 3, scale: 1

      # Projections
      add :projected_net_worth_12m, :decimal, precision: 15, scale: 2
      add :projected_net_worth_24m, :decimal, precision: 15, scale: 2
      add :projected_net_worth_60m, :decimal, precision: 15, scale: 2

      # Metadata
      add :snapshot_type, :string, null: false, default: "monthly"
      add :is_active, :boolean, null: false, default: true
      add :notes, :text

      # XBRL compliance
      add :xbrl_concept_identifier, :string
      add :xbrl_context_ref, :string
      add :xbrl_unit_ref, :string

      timestamps()
    end

    # Create indexes for efficient querying
    create index(:net_worth_snapshots, [:reporting_entity, :snapshot_date])
    create index(:net_worth_snapshots, [:reporting_entity, :reporting_period])
    create index(:net_worth_snapshots, [:snapshot_date])
    create index(:net_worth_snapshots, [:snapshot_type])
    create index(:net_worth_snapshots, [:is_active])

    # Create unique constraint to prevent duplicate snapshots
    create unique_index(:net_worth_snapshots, [:snapshot_date, :reporting_entity, :snapshot_type],
                       name: :unique_snapshot_per_entity_period_type)
  end
end
