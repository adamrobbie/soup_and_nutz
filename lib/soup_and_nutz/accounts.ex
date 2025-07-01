defmodule SoupAndNutz.Accounts do
  @moduledoc """
  The Accounts context provides business logic for managing user accounts,
  authentication, and user-related operations in the financial planning system.
  """

  import Ecto.Query, warn: false

  alias SoupAndNutz.Accounts.User
  alias SoupAndNutz.Repo

  @doc """
  Returns the list of users.
  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Returns the list of active users.
  """
  def list_active_users do
    User.list_active_users()
  end

  @doc """
  Gets a single user by ID.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user by ID, returns nil if not found.
  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a single user by ID with preloaded associations.
  """
  def get_user_with_goals!(id), do: User.get_user!(id)

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email), do: User.get_by_email(email)

  @doc """
  Gets a user by username.
  """
  def get_user_by_username(username), do: User.get_by_username(username)

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user's profile.
  """
  def update_user_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a user's password.
  """
  def update_user_password(%User{} = user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a user's account status.
  """
  def update_user_status(%User{} = user, attrs) do
    user
    |> User.status_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user profile changes.
  """
  def change_user_profile(%User{} = user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user password changes.
  """
  def change_user_password(%User{} = user, attrs \\ %{}) do
    User.password_changeset(user, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user status changes.
  """
  def change_user_status(%User{} = user, attrs \\ %{}) do
    User.status_changeset(user, attrs)
  end

  @doc """
  Updates user's last login timestamp.
  """
  def update_last_login(%User{} = user) do
    User.update_last_login(user)
  end

  @doc """
  Verifies user's email.
  """
  def verify_email(%User{} = user) do
    User.verify_email(user)
  end

  @doc """
  Lists users by account type.
  """
  def list_users_by_account_type(account_type) do
    User.list_users_by_account_type(account_type)
  end

  @doc """
  Lists users by subscription tier.
  """
  def list_users_by_subscription_tier(tier) do
    User.list_users_by_subscription_tier(tier)
  end

  @doc """
  Gets user's financial goals.
  """
  def get_user_financial_goals(%User{} = user) do
    User.get_financial_goals(user)
  end

  @doc """
  Gets user's active financial goals.
  """
  def get_user_active_financial_goals(%User{} = user) do
    User.get_active_financial_goals(user)
  end

  @doc """
  Gets user's financial goals by type.
  """
  def get_user_financial_goals_by_type(%User{} = user, goal_type) do
    User.get_financial_goals_by_type(user, goal_type)
  end

  @doc """
  Gets user's financial goals by status.
  """
  def get_user_financial_goals_by_status(%User{} = user, status) do
    User.get_financial_goals_by_status(user, status)
  end

  @doc """
  Gets user's financial goals by priority.
  """
  def get_user_financial_goals_by_priority(%User{} = user, priority) do
    User.get_financial_goals_by_priority(user, priority)
  end

  @doc """
  Gets user's financial goals by category.
  """
  def get_user_financial_goals_by_category(%User{} = user, category) do
    User.get_financial_goals_by_category(user, category)
  end

  @doc """
  Gets user's financial goals by target date range.
  """
  def get_user_financial_goals_by_date_range(%User{} = user, start_date, end_date) do
    User.get_financial_goals_by_date_range(user, start_date, end_date)
  end

  @doc """
  Gets user's financial goals by progress range.
  """
  def get_user_financial_goals_by_progress_range(%User{} = user, min_progress, max_progress) do
    User.get_financial_goals_by_progress_range(user, min_progress, max_progress)
  end

  @doc """
  Gets user's financial goals by target amount range.
  """
  def get_user_financial_goals_by_amount_range(%User{} = user, min_amount, max_amount) do
    User.get_financial_goals_by_amount_range(user, min_amount, max_amount)
  end

  @doc """
  Gets user's financial goals by currency.
  """
  def get_user_financial_goals_by_currency(%User{} = user, currency) do
    User.get_financial_goals_by_currency(user, currency)
  end

  @doc """
  Gets user's financial goals by related entity.
  """
  def get_user_financial_goals_by_related_entity(%User{} = user, entity) do
    User.get_financial_goals_by_related_entity(user, entity)
  end

  @doc """
  Gets user's financial goals by tags.
  """
  def get_user_financial_goals_by_tags(%User{} = user, tags) do
    User.get_financial_goals_by_tags(user, tags)
  end

  @doc """
  Gets user's financial goals by linked assets.
  """
  def get_user_financial_goals_by_linked_assets(%User{} = user, asset_identifiers) do
    User.get_financial_goals_by_linked_assets(user, asset_identifiers)
  end

  @doc """
  Gets user's financial goals by linked debts.
  """
  def get_user_financial_goals_by_linked_debts(%User{} = user, debt_identifiers) do
    User.get_financial_goals_by_linked_debts(user, debt_identifiers)
  end

  @doc """
  Gets user's financial goals by linked cash flows.
  """
  def get_user_financial_goals_by_linked_cash_flows(%User{} = user, cash_flow_identifiers) do
    User.get_financial_goals_by_linked_cash_flows(user, cash_flow_identifiers)
  end

  @doc """
  Gets user's financial goals by milestone date.
  """
  def get_user_financial_goals_by_milestone_date(%User{} = user, milestone_date) do
    User.get_financial_goals_by_milestone_date(user, milestone_date)
  end

  @doc """
  Gets user's financial goals by checkpoint date.
  """
  def get_user_financial_goals_by_checkpoint_date(%User{} = user, checkpoint_date) do
    User.get_financial_goals_by_checkpoint_date(user, checkpoint_date)
  end

  @doc """
  Gets user's financial goals by recurrence pattern.
  """
  def get_user_financial_goals_by_recurrence_pattern(%User{} = user, pattern) do
    User.get_financial_goals_by_recurrence_pattern(user, pattern)
  end

  @doc """
  Gets user's financial goals by notification status.
  """
  def get_user_financial_goals_by_notification_status(%User{} = user, notifications_enabled) do
    User.get_financial_goals_by_notification_status(user, notifications_enabled)
  end

  @doc """
  Gets user's financial goals by auto-adjust status.
  """
  def get_user_financial_goals_by_auto_adjust_status(%User{} = user, auto_adjust_targets) do
    User.get_financial_goals_by_auto_adjust_status(user, auto_adjust_targets)
  end

  @doc """
  Gets user's financial goals by recurring status.
  """
  def get_user_financial_goals_by_recurring_status(%User{} = user, is_recurring) do
    User.get_financial_goals_by_recurring_status(user, is_recurring)
  end

  @doc """
  Gets user's financial goals by importance level.
  """
  def get_user_financial_goals_by_importance_level(%User{} = user, importance_level) do
    User.get_financial_goals_by_importance_level(user, importance_level)
  end

  @doc """
  Gets user's financial goals by parent goal.
  """
  def get_user_financial_goals_by_parent_goal(%User{} = user, parent_goal_id) do
    User.get_financial_goals_by_parent_goal(user, parent_goal_id)
  end

  @doc """
  Gets user's financial goals by created by.
  """
  def get_user_financial_goals_by_created_by(%User{} = user, created_by) do
    User.get_financial_goals_by_created_by(user, created_by)
  end

  @doc """
  Gets user's financial goals by updated by.
  """
  def get_user_financial_goals_by_updated_by(%User{} = user, updated_by) do
    User.get_financial_goals_by_updated_by(user, updated_by)
  end

  @doc """
  Gets user's financial goals by last updated date range.
  """
  def get_user_financial_goals_by_last_updated_range(%User{} = user, start_date, end_date) do
    User.get_financial_goals_by_last_updated_range(user, start_date, end_date)
  end

  @doc """
  Gets user's financial goals by start date range.
  """
  def get_user_financial_goals_by_start_date_range(%User{} = user, start_date, end_date) do
    User.get_financial_goals_by_start_date_range(user, start_date, end_date)
  end

  @doc """
  Gets user's financial goals by created date range.
  """
  def get_user_financial_goals_by_created_date_range(%User{} = user, start_date, end_date) do
    User.get_financial_goals_by_created_date_range(user, start_date, end_date)
  end

  @doc """
  Gets user's financial goals by updated date range.
  """
  def get_user_financial_goals_by_updated_date_range(%User{} = user, start_date, end_date) do
    User.get_financial_goals_by_updated_date_range(user, start_date, end_date)
  end

  @doc """
  Gets user's financial goals by monthly contribution target range.
  """
  def get_user_financial_goals_by_monthly_contribution_range(%User{} = user, min_contribution, max_contribution) do
    User.get_financial_goals_by_monthly_contribution_range(user, min_contribution, max_contribution)
  end

  @doc """
  Gets user's financial goals by monthly contribution actual range.
  """
  def get_user_financial_goals_by_monthly_contribution_actual_range(%User{} = user, min_contribution, max_contribution) do
    User.get_financial_goals_by_monthly_contribution_actual_range(user, min_contribution, max_contribution)
  end

  @doc """
  Gets user's financial goals by current amount range.
  """
  def get_user_financial_goals_by_current_amount_range(%User{} = user, min_amount, max_amount) do
    User.get_financial_goals_by_current_amount_range(user, min_amount, max_amount)
  end

  @doc """
  Gets user's financial goal by identifier.
  """
  def get_user_financial_goal_by_identifier(%User{} = user, goal_identifier) do
    User.get_financial_goal_by_identifier(user, goal_identifier)
  end

  @doc """
  Gets user's financial goals by name.
  """
  def get_user_financial_goals_by_name(%User{} = user, goal_name) do
    User.get_financial_goals_by_name(user, goal_name)
  end

  @doc """
  Gets user's financial goals by subcategory.
  """
  def get_user_financial_goals_by_subcategory(%User{} = user, goal_subcategory) do
    User.get_financial_goals_by_subcategory(user, goal_subcategory)
  end

  @doc """
  Gets user's financial goals by XBRL concept identifier.
  """
  def get_user_financial_goals_by_xbrl_concept(%User{} = user, xbrl_concept_identifier) do
    User.get_financial_goals_by_xbrl_concept(user, xbrl_concept_identifier)
  end

  @doc """
  Gets user's financial goals by XBRL context reference.
  """
  def get_user_financial_goals_by_xbrl_context(%User{} = user, xbrl_context_ref) do
    User.get_financial_goals_by_xbrl_context(user, xbrl_context_ref)
  end

  @doc """
  Gets user's financial goals by XBRL unit reference.
  """
  def get_user_financial_goals_by_xbrl_unit(%User{} = user, xbrl_unit_ref) do
    User.get_financial_goals_by_xbrl_unit(user, xbrl_unit_ref)
  end
end
