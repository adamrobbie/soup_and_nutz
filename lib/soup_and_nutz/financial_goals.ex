defmodule SoupAndNutz.FinancialGoals do
  @moduledoc """
  The FinancialGoals context provides business logic for managing financial goals,
  progress tracking, and goal-related operations in the financial planning system.
  """

  import Ecto.Query, warn: false

  alias SoupAndNutz.FinancialGoals.FinancialGoal
  alias SoupAndNutz.Repo

  @doc """
  Returns the list of financial goals.
  """
  def list_financial_goals do
    Repo.all(FinancialGoal)
  end

  @doc """
  Returns the list of active financial goals.
  """
  def list_active_financial_goals do
    FinancialGoal
    |> where([g], g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets a single financial goal by ID.
  """
  def get_financial_goal!(id), do: FinancialGoal.get_financial_goal!(id)

  @doc """
  Gets a financial goal by identifier.
  """
  def get_financial_goal_by_identifier(goal_identifier), do: FinancialGoal.get_financial_goal_by_identifier(goal_identifier)

  @doc """
  Creates a financial goal.
  """
  def create_financial_goal(attrs \\ %{}) do
    %FinancialGoal{}
    |> FinancialGoal.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a financial goal.
  """
  def update_financial_goal(%FinancialGoal{} = financial_goal, attrs) do
    financial_goal
    |> FinancialGoal.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a financial goal's progress.
  """
  def update_financial_goal_progress(%FinancialGoal{} = financial_goal, attrs) do
    financial_goal
    |> FinancialGoal.progress_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a financial goal's status.
  """
  def update_financial_goal_status(%FinancialGoal{} = financial_goal, attrs) do
    financial_goal
    |> FinancialGoal.status_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a financial goal.
  """
  def delete_financial_goal(%FinancialGoal{} = financial_goal) do
    Repo.delete(financial_goal)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking financial goal changes.
  """
  def change_financial_goal(%FinancialGoal{} = financial_goal, attrs \\ %{}) do
    FinancialGoal.create_changeset(financial_goal, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking financial goal progress changes.
  """
  def change_financial_goal_progress(%FinancialGoal{} = financial_goal, attrs \\ %{}) do
    FinancialGoal.progress_changeset(financial_goal, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking financial goal status changes.
  """
  def change_financial_goal_status(%FinancialGoal{} = financial_goal, attrs \\ %{}) do
    FinancialGoal.status_changeset(financial_goal, attrs)
  end

  @doc """
  Lists financial goals by user.
  """
  def list_financial_goals_by_user(user_id) do
    FinancialGoal.list_financial_goals_by_user(user_id)
  end

  @doc """
  Lists financial goals by type.
  """
  def list_financial_goals_by_type(goal_type) do
    FinancialGoal.list_financial_goals_by_type(goal_type)
  end

  @doc """
  Lists financial goals by status.
  """
  def list_financial_goals_by_status(status) do
    FinancialGoal.list_financial_goals_by_status(status)
  end

  @doc """
  Lists financial goals by priority level.
  """
  def list_financial_goals_by_priority(priority_level) do
    FinancialGoal.list_financial_goals_by_priority(priority_level)
  end

  @doc """
  Lists financial goals by category.
  """
  def list_financial_goals_by_category(goal_category) do
    FinancialGoal.list_financial_goals_by_category(goal_category)
  end

  @doc """
  Lists financial goals by target date range.
  """
  def list_financial_goals_by_date_range(start_date, end_date) do
    FinancialGoal.list_financial_goals_by_date_range(start_date, end_date)
  end

  @doc """
  Lists financial goals by progress range.
  """
  def list_financial_goals_by_progress_range(min_progress, max_progress) do
    FinancialGoal.list_financial_goals_by_progress_range(min_progress, max_progress)
  end

  @doc """
  Lists financial goals by target amount range.
  """
  def list_financial_goals_by_amount_range(min_amount, max_amount) do
    FinancialGoal.list_financial_goals_by_amount_range(min_amount, max_amount)
  end

  @doc """
  Lists financial goals by currency.
  """
  def list_financial_goals_by_currency(currency_code) do
    FinancialGoal.list_financial_goals_by_currency(currency_code)
  end

  @doc """
  Lists financial goals by related entity.
  """
  def list_financial_goals_by_related_entity(related_entity) do
    FinancialGoal.list_financial_goals_by_related_entity(related_entity)
  end

  @doc """
  Lists financial goals by tags.
  """
  def list_financial_goals_by_tags(tags) do
    FinancialGoal.list_financial_goals_by_tags(tags)
  end

  @doc """
  Lists financial goals by linked assets.
  """
  def list_financial_goals_by_linked_assets(asset_identifiers) do
    FinancialGoal.list_financial_goals_by_linked_assets(asset_identifiers)
  end

  @doc """
  Lists financial goals by linked debts.
  """
  def list_financial_goals_by_linked_debts(debt_identifiers) do
    FinancialGoal.list_financial_goals_by_linked_debts(debt_identifiers)
  end

  @doc """
  Lists financial goals by linked cash flows.
  """
  def list_financial_goals_by_linked_cash_flows(cash_flow_identifiers) do
    FinancialGoal.list_financial_goals_by_linked_cash_flows(cash_flow_identifiers)
  end

  @doc """
  Lists financial goals by milestone date.
  """
  def list_financial_goals_by_milestone_date(milestone_date) do
    FinancialGoal.list_financial_goals_by_milestone_date(milestone_date)
  end

  @doc """
  Lists financial goals by checkpoint date.
  """
  def list_financial_goals_by_checkpoint_date(checkpoint_date) do
    FinancialGoal.list_financial_goals_by_checkpoint_date(checkpoint_date)
  end

  @doc """
  Lists financial goals by recurrence pattern.
  """
  def list_financial_goals_by_recurrence_pattern(recurrence_pattern) do
    FinancialGoal.list_financial_goals_by_recurrence_pattern(recurrence_pattern)
  end

  @doc """
  Lists financial goals by notification status.
  """
  def list_financial_goals_by_notification_status(notifications_enabled) do
    FinancialGoal.list_financial_goals_by_notification_status(notifications_enabled)
  end

  @doc """
  Lists financial goals by auto-adjust status.
  """
  def list_financial_goals_by_auto_adjust_status(auto_adjust_targets) do
    FinancialGoal.list_financial_goals_by_auto_adjust_status(auto_adjust_targets)
  end

  @doc """
  Lists financial goals by recurring status.
  """
  def list_financial_goals_by_recurring_status(is_recurring) do
    FinancialGoal.list_financial_goals_by_recurring_status(is_recurring)
  end

  @doc """
  Lists financial goals by importance level.
  """
  def list_financial_goals_by_importance_level(importance_level) do
    FinancialGoal.list_financial_goals_by_importance_level(importance_level)
  end

  @doc """
  Lists financial goals by parent goal.
  """
  def list_financial_goals_by_parent_goal(parent_goal_id) do
    FinancialGoal.list_financial_goals_by_parent_goal(parent_goal_id)
  end

  @doc """
  Lists financial goals by created by.
  """
  def list_financial_goals_by_created_by(created_by) do
    FinancialGoal.list_financial_goals_by_created_by(created_by)
  end

  @doc """
  Lists financial goals by updated by.
  """
  def list_financial_goals_by_updated_by(updated_by) do
    FinancialGoal.list_financial_goals_by_updated_by(updated_by)
  end

  @doc """
  Lists financial goals by last updated date range.
  """
  def list_financial_goals_by_last_updated_range(start_date, end_date) do
    FinancialGoal.list_financial_goals_by_last_updated_range(start_date, end_date)
  end

  @doc """
  Lists financial goals by start date range.
  """
  def list_financial_goals_by_start_date_range(start_date, end_date) do
    FinancialGoal.list_financial_goals_by_start_date_range(start_date, end_date)
  end

  @doc """
  Lists financial goals by created date range.
  """
  def list_financial_goals_by_created_date_range(start_date, end_date) do
    FinancialGoal.list_financial_goals_by_created_date_range(start_date, end_date)
  end

  @doc """
  Lists financial goals by updated date range.
  """
  def list_financial_goals_by_updated_date_range(start_date, end_date) do
    FinancialGoal.list_financial_goals_by_updated_date_range(start_date, end_date)
  end

  @doc """
  Lists financial goals by monthly contribution target range.
  """
  def list_financial_goals_by_monthly_contribution_range(min_contribution, max_contribution) do
    FinancialGoal.list_financial_goals_by_monthly_contribution_range(min_contribution, max_contribution)
  end

  @doc """
  Lists financial goals by monthly contribution actual range.
  """
  def list_financial_goals_by_monthly_contribution_actual_range(min_contribution, max_contribution) do
    FinancialGoal.list_financial_goals_by_monthly_contribution_actual_range(min_contribution, max_contribution)
  end

  @doc """
  Lists financial goals by current amount range.
  """
  def list_financial_goals_by_current_amount_range(min_amount, max_amount) do
    FinancialGoal.list_financial_goals_by_current_amount_range(min_amount, max_amount)
  end

  @doc """
  Lists financial goals by name.
  """
  def list_financial_goals_by_name(goal_name) do
    FinancialGoal.list_financial_goals_by_name(goal_name)
  end

  @doc """
  Lists financial goals by subcategory.
  """
  def list_financial_goals_by_subcategory(goal_subcategory) do
    FinancialGoal.list_financial_goals_by_subcategory(goal_subcategory)
  end

  @doc """
  Lists financial goals by XBRL concept identifier.
  """
  def list_financial_goals_by_xbrl_concept(xbrl_concept_identifier) do
    FinancialGoal.list_financial_goals_by_xbrl_concept(xbrl_concept_identifier)
  end

  @doc """
  Lists financial goals by XBRL context reference.
  """
  def list_financial_goals_by_xbrl_context(xbrl_context_ref) do
    FinancialGoal.list_financial_goals_by_xbrl_context(xbrl_context_ref)
  end

  @doc """
  Lists financial goals by XBRL unit reference.
  """
  def list_financial_goals_by_xbrl_unit(xbrl_unit_ref) do
    FinancialGoal.list_financial_goals_by_xbrl_unit(xbrl_unit_ref)
  end

  @doc """
  Generates a goal identifier.
  """
  def generate_goal_identifier(goal_type, user_id) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    "#{String.upcase(goal_type)}_#{user_id}_#{timestamp}"
  end

  @doc """
  Calculates goal progress percentage.
  """
  def calculate_progress_percentage(current_amount, target_amount) do
    if Decimal.gt?(target_amount, Decimal.new("0")) do
      Decimal.mult(Decimal.div(current_amount, target_amount), Decimal.new("100"))
    else
      Decimal.new("0")
    end
  end

  @doc """
  Updates goal progress based on current amount.
  """
  def update_goal_progress(%FinancialGoal{} = goal, current_amount) do
    progress_percentage = calculate_progress_percentage(current_amount, goal.target_amount)

    goal
    |> Ecto.Changeset.change(%{
      current_amount: current_amount,
      progress_percentage: progress_percentage,
      last_updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end

  @doc """
  Checks if a goal is completed.
  """
  def goal_completed?(%FinancialGoal{} = goal) do
    Decimal.gte?(goal.current_amount, goal.target_amount)
  end

  @doc """
  Gets goals that are due soon (within specified days).
  """
  def get_goals_due_soon(days \\ 30) do
    target_date = Date.add(Date.utc_today(), days)

    FinancialGoal
    |> where([g], g.target_date <= ^target_date and g.status == "Active" and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals that are overdue.
  """
  def get_overdue_goals do
    today = Date.utc_today()

    FinancialGoal
    |> where([g], g.target_date < ^today and g.status == "Active" and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals with milestones due soon.
  """
  def get_goals_with_milestones_due_soon(days \\ 7) do
    milestone_date = Date.add(Date.utc_today(), days)

    FinancialGoal
    |> where([g], g.next_milestone_date <= ^milestone_date and g.status == "Active" and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals with checkpoints due soon.
  """
  def get_goals_with_checkpoints_due_soon(days \\ 7) do
    checkpoint_date = Date.add(Date.utc_today(), days)

    FinancialGoal
    |> where([g], g.next_checkpoint_date <= ^checkpoint_date and g.status == "Active" and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals that need attention (low progress, overdue, etc.).
  """
  def get_goals_needing_attention do
    today = Date.utc_today()
    thirty_days_ago = Date.add(today, -30)

    FinancialGoal
    |> where([g],
      (g.status == "Active" and g.is_active == true) and
      (
        g.target_date < ^today or
        g.progress_percentage < 25.0 or
        g.last_updated_at < ^thirty_days_ago
      )
    )
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and type.
  """
  def get_goals_by_user_and_type(user_id, goal_type) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.goal_type == ^goal_type and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and status.
  """
  def get_goals_by_user_and_status(user_id, status) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.status == ^status and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and priority.
  """
  def get_goals_by_user_and_priority(user_id, priority) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.priority_level == ^priority and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and category.
  """
  def get_goals_by_user_and_category(user_id, category) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.goal_category == ^category and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and currency.
  """
  def get_goals_by_user_and_currency(user_id, currency) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.currency_code == ^currency and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and progress range.
  """
  def get_goals_by_user_and_progress_range(user_id, min_progress, max_progress) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.progress_percentage >= ^min_progress and g.progress_percentage <= ^max_progress and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and amount range.
  """
  def get_goals_by_user_and_amount_range(user_id, min_amount, max_amount) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.target_amount >= ^min_amount and g.target_amount <= ^max_amount and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and date range.
  """
  def get_goals_by_user_and_date_range(user_id, start_date, end_date) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.target_date >= ^start_date and g.target_date <= ^end_date and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and tags.
  """
  def get_goals_by_user_and_tags(user_id, tags) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and fragment("? && ?", g.tags, ^tags) and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and linked assets.
  """
  def get_goals_by_user_and_linked_assets(user_id, asset_identifiers) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and fragment("? && ?", g.linked_assets, ^asset_identifiers) and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and linked debts.
  """
  def get_goals_by_user_and_linked_debts(user_id, debt_identifiers) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and fragment("? && ?", g.linked_debts, ^debt_identifiers) and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and linked cash flows.
  """
  def get_goals_by_user_and_linked_cash_flows(user_id, cash_flow_identifiers) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and fragment("? && ?", g.linked_cash_flows, ^cash_flow_identifiers) and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and milestone date.
  """
  def get_goals_by_user_and_milestone_date(user_id, milestone_date) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.next_milestone_date == ^milestone_date and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and checkpoint date.
  """
  def get_goals_by_user_and_checkpoint_date(user_id, checkpoint_date) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.next_checkpoint_date == ^checkpoint_date and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and recurrence pattern.
  """
  def get_goals_by_user_and_recurrence_pattern(user_id, pattern) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.recurrence_pattern == ^pattern and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and notification status.
  """
  def get_goals_by_user_and_notification_status(user_id, notifications_enabled) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.notifications_enabled == ^notifications_enabled and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and auto-adjust status.
  """
  def get_goals_by_user_and_auto_adjust_status(user_id, auto_adjust_targets) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.auto_adjust_targets == ^auto_adjust_targets and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and recurring status.
  """
  def get_goals_by_user_and_recurring_status(user_id, is_recurring) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.is_recurring == ^is_recurring and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and importance level.
  """
  def get_goals_by_user_and_importance_level(user_id, importance_level) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.importance_level == ^importance_level and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and parent goal.
  """
  def get_goals_by_user_and_parent_goal(user_id, parent_goal_id) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.parent_goal_id == ^parent_goal_id and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and created by.
  """
  def get_goals_by_user_and_created_by(user_id, created_by) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.created_by == ^created_by and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and updated by.
  """
  def get_goals_by_user_and_updated_by(user_id, updated_by) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.updated_by == ^updated_by and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and last updated range.
  """
  def get_goals_by_user_and_last_updated_range(user_id, start_date, end_date) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.last_updated_at >= ^start_date and g.last_updated_at <= ^end_date and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and start date range.
  """
  def get_goals_by_user_and_start_date_range(user_id, start_date, end_date) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.start_date >= ^start_date and g.start_date <= ^end_date and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and created date range.
  """
  def get_goals_by_user_and_created_date_range(user_id, start_date, end_date) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.inserted_at >= ^start_date and g.inserted_at <= ^end_date and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and updated date range.
  """
  def get_goals_by_user_and_updated_date_range(user_id, start_date, end_date) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.updated_at >= ^start_date and g.updated_at <= ^end_date and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and monthly contribution target range.
  """
  def get_goals_by_user_and_monthly_contribution_range(user_id, min_contribution, max_contribution) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.monthly_contribution_target >= ^min_contribution and g.monthly_contribution_target <= ^max_contribution and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and monthly contribution actual range.
  """
  def get_goals_by_user_and_monthly_contribution_actual_range(user_id, min_contribution, max_contribution) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.monthly_contribution_actual >= ^min_contribution and g.monthly_contribution_actual <= ^max_contribution and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and current amount range.
  """
  def get_goals_by_user_and_current_amount_range(user_id, min_amount, max_amount) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.current_amount >= ^min_amount and g.current_amount <= ^max_amount and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goal by user and identifier.
  """
  def get_goal_by_user_and_identifier(user_id, goal_identifier) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.goal_identifier == ^goal_identifier and g.is_active == true)
    |> Repo.one()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and name.
  """
  def get_goals_by_user_and_name(user_id, goal_name) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.goal_name == ^goal_name and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and subcategory.
  """
  def get_goals_by_user_and_subcategory(user_id, goal_subcategory) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.goal_subcategory == ^goal_subcategory and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and XBRL concept identifier.
  """
  def get_goals_by_user_and_xbrl_concept(user_id, xbrl_concept_identifier) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.xbrl_concept_identifier == ^xbrl_concept_identifier and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and XBRL context reference.
  """
  def get_goals_by_user_and_xbrl_context(user_id, xbrl_context_ref) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.xbrl_context_ref == ^xbrl_context_ref and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end

  @doc """
  Gets goals by user and XBRL unit reference.
  """
  def get_goals_by_user_and_xbrl_unit(user_id, xbrl_unit_ref) do
    FinancialGoal
    |> where([g], g.user_id == ^user_id and g.xbrl_unit_ref == ^xbrl_unit_ref and g.is_active == true)
    |> Repo.all()
    |> Repo.preload([:user, :parent_goal])
  end
end
