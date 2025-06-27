defmodule SoupAndNutz.Repo.Migrations.CreateFinancialGoals do
  use Ecto.Migration

  def change do
    create table(:financial_goals) do
      # Basic goal information
      add :goal_identifier, :string, null: false
      add :goal_name, :string, null: false
      add :goal_description, :text
      add :goal_type, :string, null: false  # Savings, DebtPayoff, Investment, Retirement, EmergencyFund, etc.
      add :goal_category, :string  # ShortTerm, MediumTerm, LongTerm
      add :goal_subcategory, :string  # Specific type within category

      # Financial targets
      add :target_amount, :decimal, precision: 15, scale: 2, null: false
      add :current_amount, :decimal, precision: 15, scale: 2, default: 0.0
      add :currency_code, :string, default: "USD", null: false
      add :target_date, :date
      add :start_date, :date, null: false

      # Progress tracking
      add :progress_percentage, :decimal, precision: 5, scale: 2, default: 0.0
      add :monthly_contribution_target, :decimal, precision: 15, scale: 2
      add :monthly_contribution_actual, :decimal, precision: 15, scale: 2, default: 0.0
      add :last_updated_at, :utc_datetime

      # Goal status and priority
      add :status, :string, default: "Active"  # Active, Paused, Completed, Cancelled
      add :priority_level, :string, default: "Medium"  # Low, Medium, High, Critical
      add :importance_level, :string, default: "Important"  # Essential, Important, NiceToHave, Luxury

      # Goal relationships and dependencies
      add :parent_goal_id, references(:financial_goals, on_delete: :nilify_all)
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :related_entity, :string  # Links to specific assets, debts, or cash flows

      # Milestones and checkpoints
      add :milestones, :map, default: %{}
      add :checkpoints, :map, default: %{}
      add :next_milestone_date, :date
      add :next_checkpoint_date, :date

      # Goal settings and preferences
      add :is_recurring, :boolean, default: false
      add :recurrence_pattern, :string  # Monthly, Quarterly, Annual
      add :auto_adjust_targets, :boolean, default: false
      add :notifications_enabled, :boolean, default: true

      # Integration with financial instruments
      add :linked_assets, {:array, :string}  # Array of asset identifiers
      add :linked_debts, {:array, :string}   # Array of debt identifiers
      add :linked_cash_flows, {:array, :string}  # Array of cash flow identifiers

      # Metadata and tracking
      add :tags, {:array, :string}
      add :is_active, :boolean, default: true
      add :notes, :text
      add :created_by, :string
      add :updated_by, :string

      # XBRL compliance
      add :xbrl_concept_identifier, :string
      add :xbrl_context_ref, :string
      add :xbrl_unit_ref, :string

      timestamps(type: :utc_datetime)
    end

    # Create indexes for better performance
    create unique_index(:financial_goals, [:goal_identifier])
    create index(:financial_goals, [:user_id])
    create index(:financial_goals, [:goal_type])
    create index(:financial_goals, [:goal_category])
    create index(:financial_goals, [:status])
    create index(:financial_goals, [:priority_level])
    create index(:financial_goals, [:target_date])
    create index(:financial_goals, [:start_date])
    create index(:financial_goals, [:progress_percentage])
    create index(:financial_goals, [:is_active])
    create index(:financial_goals, [:parent_goal_id])
    create index(:financial_goals, [:related_entity])
    create index(:financial_goals, [:currency_code])
    create index(:financial_goals, [:inserted_at])
    create index(:financial_goals, [:updated_at])
  end
end
