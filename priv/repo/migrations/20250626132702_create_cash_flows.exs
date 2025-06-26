defmodule SoupAndNutz.Repo.Migrations.CreateCashFlows do
  use Ecto.Migration

  def change do
    create table(:cash_flows) do
      # XBRL-inspired identifier fields
      add :cash_flow_identifier, :string, null: false
      add :cash_flow_name, :string, null: false
      add :cash_flow_type, :string, null: false  # "Income" or "Expense"
      add :cash_flow_category, :string, null: false
      add :cash_flow_subcategory, :string

      # Financial measurement fields
      add :amount, :decimal, precision: 15, scale: 2, null: false
      add :currency_code, :string, null: false
      add :transaction_date, :date, null: false
      add :effective_date, :date, null: false

      # XBRL context fields
      add :reporting_period, :string, null: false  # e.g., "2024-12", "2024-Q4"
      add :reporting_entity, :string, null: false
      add :reporting_scenario, :string  # "Actual", "Budget", "Forecast"

      # Cash flow specific fields
      add :frequency, :string  # "OneTime", "Monthly", "Quarterly", "Annual"
      add :is_recurring, :boolean, default: false
      add :recurrence_pattern, :string  # "Daily", "Weekly", "Monthly", "Quarterly", "Annual"
      add :next_occurrence_date, :date
      add :end_date, :date  # For recurring transactions

      # Source and destination tracking
      add :source_account, :string  # Bank account, credit card, etc.
      add :destination_account, :string
      add :payment_method, :string  # "Cash", "Check", "CreditCard", "BankTransfer", "Digital"

      # Budget and planning fields
      add :budgeted_amount, :decimal, precision: 15, scale: 2
      add :budget_period, :string  # "Monthly", "Quarterly", "Annual"
      add :is_budget_item, :boolean, default: false
      add :budget_category, :string

      # Additional metadata
      add :description, :text
      add :notes, :text
      add :tags, {:array, :string}  # For flexible categorization
      add :is_active, :boolean, default: true
      add :is_tax_deductible, :boolean, default: false
      add :tax_category, :string  # For tax planning

      # Priority and importance
      add :priority_level, :string  # "Critical", "High", "Medium", "Low"
      add :importance_level, :string  # "Essential", "Important", "NiceToHave", "Luxury"

      # XBRL validation fields
      add :validation_status, :string, default: "Pending"
      add :last_validated_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    # Create indexes for better performance
    create unique_index(:cash_flows, [:cash_flow_identifier])
    create index(:cash_flows, [:cash_flow_type])
    create index(:cash_flows, [:cash_flow_category])
    create index(:cash_flows, [:reporting_entity])
    create index(:cash_flows, [:reporting_period])
    create index(:cash_flows, [:transaction_date])
    create index(:cash_flows, [:effective_date])
    create index(:cash_flows, [:currency_code])
    create index(:cash_flows, [:is_active])
    create index(:cash_flows, [:is_recurring])
    create index(:cash_flows, [:is_budget_item])
    create index(:cash_flows, [:frequency])
    create index(:cash_flows, [:source_account])
    create index(:cash_flows, [:payment_method])
    create index(:cash_flows, [:priority_level])
    create index(:cash_flows, [:importance_level])
    create index(:cash_flows, [:is_tax_deductible])
  end
end
