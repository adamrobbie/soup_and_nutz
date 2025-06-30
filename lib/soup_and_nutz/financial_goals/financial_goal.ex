defmodule SoupAndNutz.FinancialGoals.FinancialGoal do
  @moduledoc """
  Schema and business logic for financial goals in the financial planning system.

  This module manages financial goals including savings, debt payoff, investment,
  retirement, and other financial objectives with progress tracking and milestone management.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias SoupAndNutz.FinancialGoals.FinancialGoal
  alias SoupAndNutz.Accounts.User
  alias SoupAndNutz.Repo

  schema "financial_goals" do
    # Basic goal information
    field :goal_identifier, :string
    field :goal_name, :string
    field :goal_description, :string
    field :goal_type, :string
    field :goal_category, :string
    field :goal_subcategory, :string

    # Financial targets
    field :target_amount, :decimal
    field :current_amount, :decimal, default: Decimal.new("0")
    field :currency_code, :string, default: "USD"
    field :target_date, :date
    field :start_date, :date

    # Progress tracking
    field :progress_percentage, :decimal, default: Decimal.new("0")
    field :monthly_contribution_target, :decimal
    field :monthly_contribution_actual, :decimal, default: Decimal.new("0")
    field :last_updated_at, :utc_datetime

    # Goal status and priority
    field :status, :string, default: "Active"
    field :priority_level, :string, default: "Medium"
    field :importance_level, :string, default: "Important"

    # Goal relationships and dependencies
    field :related_entity, :string

    # Milestones and checkpoints
    field :milestones, :map, default: %{}
    field :checkpoints, :map, default: %{}
    field :next_milestone_date, :date
    field :next_checkpoint_date, :date

    # Goal settings and preferences
    field :is_recurring, :boolean, default: false
    field :recurrence_pattern, :string
    field :auto_adjust_targets, :boolean, default: false
    field :notifications_enabled, :boolean, default: true

    # Integration with financial instruments
    field :linked_assets, {:array, :string}
    field :linked_debts, {:array, :string}
    field :linked_cash_flows, {:array, :string}

    # Metadata and tracking
    field :tags, {:array, :string}
    field :is_active, :boolean, default: true
    field :notes, :string
    field :created_by, :string
    field :updated_by, :string

    # XBRL compliance
    field :xbrl_concept_identifier, :string
    field :xbrl_context_ref, :string
    field :xbrl_unit_ref, :string

    # Associations
    belongs_to :user, User
    belongs_to :parent_goal, FinancialGoal

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for creating a new financial goal.
  """
  def create_changeset(financial_goal, attrs) do
    financial_goal
    |> cast(attrs, [
      :goal_identifier, :goal_name, :goal_description, :goal_type, :goal_category, :goal_subcategory,
      :target_amount, :current_amount, :currency_code, :target_date, :start_date,
      :progress_percentage, :monthly_contribution_target, :monthly_contribution_actual,
      :status, :priority_level, :importance_level, :related_entity,
      :milestones, :checkpoints, :next_milestone_date, :next_checkpoint_date,
      :is_recurring, :recurrence_pattern, :auto_adjust_targets, :notifications_enabled,
      :linked_assets, :linked_debts, :linked_cash_flows, :tags, :notes, :created_by, :updated_by,
      :xbrl_concept_identifier, :xbrl_context_ref, :xbrl_unit_ref, :user_id
    ])
    |> validate_required([:goal_identifier, :goal_name, :goal_type, :target_amount, :start_date, :user_id])
    |> validate_goal_data()
    |> validate_financial_data()
    |> validate_goal_relationships()
    |> unique_constraint(:goal_identifier)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:parent_goal_id)
    |> calculate_progress_percentage()
  end

  @doc """
  Creates a changeset for updating a financial goal.
  """
  def update_changeset(financial_goal, attrs) do
    financial_goal
    |> cast(attrs, [
      :goal_name, :goal_description, :goal_category, :goal_subcategory,
      :target_amount, :current_amount, :currency_code, :target_date,
      :progress_percentage, :monthly_contribution_target, :monthly_contribution_actual,
      :status, :priority_level, :importance_level, :related_entity,
      :milestones, :checkpoints, :next_milestone_date, :next_checkpoint_date,
      :is_recurring, :recurrence_pattern, :auto_adjust_targets, :notifications_enabled,
      :linked_assets, :linked_debts, :linked_cash_flows, :tags, :notes, :updated_by,
      :xbrl_concept_identifier, :xbrl_context_ref, :xbrl_unit_ref
    ])
    |> validate_goal_data()
    |> validate_financial_data()
    |> validate_goal_relationships()
    |> calculate_progress_percentage()
  end

  @doc """
  Creates a changeset for updating goal progress.
  """
  def progress_changeset(financial_goal, attrs) do
    financial_goal
    |> cast(attrs, [:current_amount, :monthly_contribution_actual])
    |> validate_required([:current_amount])
    |> validate_financial_data()
    |> calculate_progress_percentage()
    |> put_change(:last_updated_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Creates a changeset for updating goal status.
  """
  def status_changeset(financial_goal, attrs) do
    financial_goal
    |> cast(attrs, [:status, :notes, :updated_by])
    |> validate_required([:status])
    |> validate_inclusion(:status, ["Active", "Paused", "Completed", "Cancelled"])
  end

  @doc """
  Gets a financial goal by ID.
  """
  def get_financial_goal!(id) do
    FinancialGoal
    |> Repo.get!(id)
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets a financial goal by identifier.
  """
  def get_financial_goal_by_identifier(goal_identifier) do
    FinancialGoal
    |> Repo.get_by(goal_identifier: goal_identifier)
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists all financial goals for a user.
  """
  def list_financial_goals_by_user(user_id) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by type.
  """
  def list_financial_goals_by_type(goal_type) do
    FinancialGoal
    |> where([g], g.goal_type == ^goal_type and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by status.
  """
  def list_financial_goals_by_status(status) do
    FinancialGoal
    |> where([g], g.status == ^status and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by priority level.
  """
  def list_financial_goals_by_priority(priority_level) do
    FinancialGoal
    |> where([g], g.priority_level == ^priority_level and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by category.
  """
  def list_financial_goals_by_category(goal_category) do
    FinancialGoal
    |> where([g], g.goal_category == ^goal_category and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by target date range.
  """
  def list_financial_goals_by_date_range(start_date, end_date) do
    FinancialGoal
    |> where([g], g.target_date >= ^start_date and g.target_date <= ^end_date and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by progress range.
  """
  def list_financial_goals_by_progress_range(min_progress, max_progress) do
    FinancialGoal
    |> where([g], g.progress_percentage >= ^min_progress and g.progress_percentage <= ^max_progress and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by target amount range.
  """
  def list_financial_goals_by_amount_range(min_amount, max_amount) do
    FinancialGoal
    |> where([g], g.target_amount >= ^min_amount and g.target_amount <= ^max_amount and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by currency.
  """
  def list_financial_goals_by_currency(currency_code) do
    FinancialGoal
    |> where([g], g.currency_code == ^currency_code and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by related entity.
  """
  def list_financial_goals_by_related_entity(related_entity) do
    FinancialGoal
    |> where([g], g.related_entity == ^related_entity and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by tags.
  """
  def list_financial_goals_by_tags(tags) do
    FinancialGoal
    |> where([g], fragment("? && ?", g.tags, ^tags) and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by linked assets.
  """
  def list_financial_goals_by_linked_assets(asset_identifiers) do
    FinancialGoal
    |> where([g], fragment("? && ?", g.linked_assets, ^asset_identifiers) and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by linked debts.
  """
  def list_financial_goals_by_linked_debts(debt_identifiers) do
    FinancialGoal
    |> where([g], fragment("? && ?", g.linked_debts, ^debt_identifiers) and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by linked cash flows.
  """
  def list_financial_goals_by_linked_cash_flows(cash_flow_identifiers) do
    FinancialGoal
    |> where([g], fragment("? && ?", g.linked_cash_flows, ^cash_flow_identifiers) and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by milestone date.
  """
  def list_financial_goals_by_milestone_date(milestone_date) do
    FinancialGoal
    |> where([g], g.next_milestone_date == ^milestone_date and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by checkpoint date.
  """
  def list_financial_goals_by_checkpoint_date(checkpoint_date) do
    FinancialGoal
    |> where([g], g.next_checkpoint_date == ^checkpoint_date and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by recurrence pattern.
  """
  def list_financial_goals_by_recurrence_pattern(recurrence_pattern) do
    FinancialGoal
    |> where([g], g.recurrence_pattern == ^recurrence_pattern and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by notification status.
  """
  def list_financial_goals_by_notification_status(notifications_enabled) do
    FinancialGoal
    |> where([g], g.notifications_enabled == ^notifications_enabled and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by auto-adjust status.
  """
  def list_financial_goals_by_auto_adjust_status(auto_adjust_targets) do
    FinancialGoal
    |> where([g], g.auto_adjust_targets == ^auto_adjust_targets and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by recurring status.
  """
  def list_financial_goals_by_recurring_status(is_recurring) do
    FinancialGoal
    |> where([g], g.is_recurring == ^is_recurring and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by importance level.
  """
  def list_financial_goals_by_importance_level(importance_level) do
    FinancialGoal
    |> where([g], g.importance_level == ^importance_level and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by parent goal.
  """
  def list_financial_goals_by_parent_goal(parent_goal_id) do
    FinancialGoal
    |> where([g], g.parent_goal_id == ^parent_goal_id and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by created by.
  """
  def list_financial_goals_by_created_by(created_by) do
    FinancialGoal
    |> where([g], g.created_by == ^created_by and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by updated by.
  """
  def list_financial_goals_by_updated_by(updated_by) do
    FinancialGoal
    |> where([g], g.updated_by == ^updated_by and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by last updated date range.
  """
  def list_financial_goals_by_last_updated_range(start_date, end_date) do
    FinancialGoal
    |> where([g], g.last_updated_at >= ^start_date and g.last_updated_at <= ^end_date and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by start date range.
  """
  def list_financial_goals_by_start_date_range(start_date, end_date) do
    FinancialGoal
    |> where([g], g.start_date >= ^start_date and g.start_date <= ^end_date and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by created date range.
  """
  def list_financial_goals_by_created_date_range(start_date, end_date) do
    FinancialGoal
    |> where([g], g.inserted_at >= ^start_date and g.inserted_at <= ^end_date and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by updated date range.
  """
  def list_financial_goals_by_updated_date_range(start_date, end_date) do
    FinancialGoal
    |> where([g], g.updated_at >= ^start_date and g.updated_at <= ^end_date and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by monthly contribution target range.
  """
  def list_financial_goals_by_monthly_contribution_range(min_contribution, max_contribution) do
    FinancialGoal
    |> where([g], g.monthly_contribution_target >= ^min_contribution and g.monthly_contribution_target <= ^max_contribution and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by monthly contribution actual range.
  """
  def list_financial_goals_by_monthly_contribution_actual_range(min_contribution, max_contribution) do
    FinancialGoal
    |> where([g], g.monthly_contribution_actual >= ^min_contribution and g.monthly_contribution_actual <= ^max_contribution and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by current amount range.
  """
  def list_financial_goals_by_current_amount_range(min_amount, max_amount) do
    FinancialGoal
    |> where([g], g.current_amount >= ^min_amount and g.current_amount <= ^max_amount and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by goal name.
  """
  def list_financial_goals_by_name(goal_name) do
    FinancialGoal
    |> where([g], g.goal_name == ^goal_name and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by goal subcategory.
  """
  def list_financial_goals_by_subcategory(goal_subcategory) do
    FinancialGoal
    |> where([g], g.goal_subcategory == ^goal_subcategory and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by XBRL concept identifier.
  """
  def list_financial_goals_by_xbrl_concept(xbrl_concept_identifier) do
    FinancialGoal
    |> where([g], g.xbrl_concept_identifier == ^xbrl_concept_identifier and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by XBRL context reference.
  """
  def list_financial_goals_by_xbrl_context(xbrl_context_ref) do
    FinancialGoal
    |> where([g], g.xbrl_context_ref == ^xbrl_context_ref and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Lists financial goals by XBRL unit reference.
  """
  def list_financial_goals_by_xbrl_unit(xbrl_unit_ref) do
    FinancialGoal
    |> where([g], g.xbrl_unit_ref == ^xbrl_unit_ref and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  # Private validation functions

  defp validate_goal_data(changeset) do
    changeset
    |> validate_required([:goal_name, :goal_type])
    |> validate_length(:goal_name, min: 1, max: 100)
    |> validate_length(:goal_description, max: 500)
    |> validate_length(:goal_category, max: 50)
    |> validate_length(:goal_subcategory, max: 50)
    |> validate_length(:related_entity, max: 100)
    |> validate_length(:notes, max: 1000)
    |> validate_length(:created_by, max: 100)
    |> validate_length(:updated_by, max: 100)
    |> validate_inclusion(:goal_type, ["Savings", "DebtPayoff", "Investment", "Retirement", "EmergencyFund", "Education", "HomePurchase", "VehiclePurchase", "Vacation", "Wedding", "Business", "Other"])
    |> validate_inclusion(:goal_category, ["ShortTerm", "MediumTerm", "LongTerm"])
    |> validate_inclusion(:status, ["Active", "Paused", "Completed", "Cancelled"])
    |> validate_inclusion(:priority_level, ["Low", "Medium", "High", "Critical"])
    |> validate_inclusion(:importance_level, ["Essential", "Important", "NiceToHave", "Luxury"])
    |> validate_inclusion(:recurrence_pattern, ["Daily", "Weekly", "Monthly", "Quarterly", "Annual"])
    |> validate_inclusion(:currency_code, ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "CHF", "CNY"])
  end

  defp validate_financial_data(changeset) do
    changeset
    |> validate_required([:target_amount])
    |> validate_number(:target_amount, greater_than: 0)
    |> validate_number(:current_amount, greater_than_or_equal_to: 0)
    |> validate_number(:progress_percentage, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_number(:monthly_contribution_target, greater_than_or_equal_to: 0)
    |> validate_number(:monthly_contribution_actual, greater_than_or_equal_to: 0)
  end

  defp validate_goal_relationships(changeset) do
    changeset
    |> validate_number(:parent_goal_id, greater_than: 0)
  end

  defp calculate_progress_percentage(%Ecto.Changeset{valid?: true, changes: %{current_amount: current_amount, target_amount: target_amount}} = changeset) do
    progress = if Decimal.gt?(target_amount, Decimal.new("0")) do
      Decimal.mult(Decimal.div(current_amount, target_amount), Decimal.new("100"))
    else
      Decimal.new("0")
    end
    put_change(changeset, :progress_percentage, progress)
  end

  defp calculate_progress_percentage(changeset), do: changeset
end
