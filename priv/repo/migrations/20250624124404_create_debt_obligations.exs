defmodule SoupAndNutz.Repo.Migrations.CreateDebtObligations do
  use Ecto.Migration

  def change do
    create table(:debt_obligations) do
      # XBRL-inspired identifier fields
      add :debt_identifier, :string, null: false
      add :debt_name, :string, null: false
      add :debt_type, :string, null: false
      add :debt_category, :string
      
      # Financial measurement fields
      add :principal_amount, :decimal, precision: 15, scale: 2
      add :outstanding_balance, :decimal, precision: 15, scale: 2
      add :interest_rate, :decimal, precision: 5, scale: 2
      add :currency_code, :string, null: false
      add :measurement_date, :date, null: false
      
      # XBRL context fields
      add :reporting_period, :string, null: false
      add :reporting_entity, :string, null: false
      add :reporting_scenario, :string
      
      # Debt-specific fields
      add :lender_name, :string
      add :account_number, :string
      add :maturity_date, :date
      add :payment_frequency, :string
      add :monthly_payment, :decimal, precision: 15, scale: 2
      add :next_payment_date, :date
      
      # Additional metadata
      add :description, :text
      add :is_active, :boolean, default: true
      add :is_secured, :boolean, default: false
      add :collateral_description, :text
      add :risk_level, :string
      add :priority_level, :string
      
      # XBRL validation fields
      add :validation_status, :string, default: "Pending"
      add :last_validated_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    # Create indexes for better performance
    create unique_index(:debt_obligations, [:debt_identifier])
    create index(:debt_obligations, [:debt_type])
    create index(:debt_obligations, [:reporting_entity])
    create index(:debt_obligations, [:reporting_period])
    create index(:debt_obligations, [:measurement_date])
    create index(:debt_obligations, [:currency_code])
    create index(:debt_obligations, [:is_active])
    create index(:debt_obligations, [:lender_name])
    create index(:debt_obligations, [:maturity_date])
    create index(:debt_obligations, [:next_payment_date])
  end
end
