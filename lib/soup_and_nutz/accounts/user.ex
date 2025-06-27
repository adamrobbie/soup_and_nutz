defmodule SoupAndNutz.Accounts.User do
  @moduledoc """
  Schema and business logic for user accounts in the financial planning system.

  This module manages user authentication, profiles, preferences, and account settings
  for the financial planning application.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias SoupAndNutz.Accounts.User
  alias SoupAndNutz.FinancialGoals.FinancialGoal
  alias SoupAndNutz.Repo

  schema "users" do
    # Authentication fields
    field :email, :string
    field :username, :string
    field :password_hash, :string
    field :is_active, :boolean, default: true
    field :email_verified_at, :utc_datetime
    field :last_login_at, :utc_datetime

    # Profile information
    field :first_name, :string
    field :last_name, :string
    field :date_of_birth, :date
    field :phone_number, :string
    field :timezone, :string, default: "UTC"
    field :locale, :string, default: "en"

    # Financial preferences and settings
    field :preferred_currency, :string, default: "USD"
    field :default_reporting_period, :string, default: "Monthly"
    field :financial_year_start, :date
    field :tax_year_end, :date
    field :risk_tolerance, :string, default: "Medium"
    field :investment_horizon, :string, default: "LongTerm"

    # Privacy and data settings
    field :data_sharing_preferences, :map, default: %{}
    field :notification_preferences, :map, default: %{}
    field :privacy_level, :string, default: "Private"

    # Account management
    field :account_type, :string, default: "Individual"
    field :subscription_tier, :string, default: "Free"
    field :subscription_expires_at, :utc_datetime

    # Metadata
    field :created_by, :string
    field :notes, :string

    # Virtual fields for password handling
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    # Associations
    has_many :financial_goals, FinancialGoal
    has_many :assets, SoupAndNutz.FinancialInstruments.Asset
    has_many :debt_obligations, SoupAndNutz.FinancialInstruments.DebtObligation
    has_many :cash_flows, SoupAndNutz.FinancialInstruments.CashFlow
    has_many :net_worth_snapshots, SoupAndNutz.FinancialInstruments.NetWorthSnapshot

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for user registration.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email, :username, :password, :password_confirmation,
      :first_name, :last_name, :date_of_birth, :phone_number,
      :timezone, :locale, :preferred_currency, :default_reporting_period,
      :financial_year_start, :tax_year_end, :risk_tolerance, :investment_horizon,
      :data_sharing_preferences, :notification_preferences, :privacy_level,
      :account_type, :created_by, :notes
    ])
    |> validate_required([:email, :username, :password, :password_confirmation])
    |> validate_email()
    |> validate_username()
    |> validate_password()
    |> validate_financial_preferences()
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> put_password_hash()
  end

  @doc """
  Creates a changeset for user profile updates.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :first_name, :last_name, :date_of_birth, :phone_number,
      :timezone, :locale, :preferred_currency, :default_reporting_period,
      :financial_year_start, :tax_year_end, :risk_tolerance, :investment_horizon,
      :data_sharing_preferences, :notification_preferences, :privacy_level,
      :account_type, :notes
    ])
    |> validate_financial_preferences()
    |> validate_profile_data()
  end

  @doc """
  Creates a changeset for password updates.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_password()
    |> put_password_hash()
  end

  @doc """
  Creates a changeset for account status updates.
  """
  def status_changeset(user, attrs) do
    user
    |> cast(attrs, [:is_active, :subscription_tier, :subscription_expires_at])
    |> validate_required([:is_active, :subscription_tier])
    |> validate_subscription_data()
  end

  @doc """
  Gets a user by email.
  """
  def get_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by username.
  """
  def get_by_username(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Gets a user by ID with preloaded associations.
  """
  def get_user!(id) do
    User
    |> Repo.get!(id)
    |> Repo.preload([
      :financial_goals,
      :assets,
      :debt_obligations,
      :cash_flows,
      :net_worth_snapshots
    ])
  end

  @doc """
  Lists all active users.
  """
  def list_active_users do
    User
    |> where([u], u.is_active == true)
    |> Repo.all()
  end

  @doc """
  Lists users by account type.
  """
  def list_users_by_account_type(account_type) do
    User
    |> where([u], u.account_type == ^account_type and u.is_active == true)
    |> Repo.all()
  end

  @doc """
  Lists users by subscription tier.
  """
  def list_users_by_subscription_tier(tier) do
    User
    |> where([u], u.subscription_tier == ^tier and u.is_active == true)
    |> Repo.all()
  end

  @doc """
  Updates user's last login timestamp.
  """
  def update_last_login(user) do
    user
    |> change(%{last_login_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  @doc """
  Verifies user's email.
  """
  def verify_email(user) do
    user
    |> change(%{email_verified_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  @doc """
  Gets user's financial goals.
  """
  def get_financial_goals(user) do
    user
    |> Repo.preload([:financial_goals])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's active financial goals.
  """
  def get_active_financial_goals(user) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by type.
  """
  def get_financial_goals_by_type(user, goal_type) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.goal_type == ^goal_type and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by status.
  """
  def get_financial_goals_by_status(user, status) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.status == ^status and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by priority.
  """
  def get_financial_goals_by_priority(user, priority) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.priority_level == ^priority and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by category.
  """
  def get_financial_goals_by_category(user, category) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.goal_category == ^category and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by target date range.
  """
  def get_financial_goals_by_date_range(user, start_date, end_date) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.target_date >= ^start_date and g.target_date <= ^end_date and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by progress range.
  """
  def get_financial_goals_by_progress_range(user, min_progress, max_progress) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.progress_percentage >= ^min_progress and g.progress_percentage <= ^max_progress and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by target amount range.
  """
  def get_financial_goals_by_amount_range(user, min_amount, max_amount) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.target_amount >= ^min_amount and g.target_amount <= ^max_amount and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by currency.
  """
  def get_financial_goals_by_currency(user, currency) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.currency_code == ^currency and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by related entity.
  """
  def get_financial_goals_by_related_entity(user, entity) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.related_entity == ^entity and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by tags.
  """
  def get_financial_goals_by_tags(user, tags) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: fragment("? && ?", g.tags, ^tags) and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by linked assets.
  """
  def get_financial_goals_by_linked_assets(user, asset_identifiers) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: fragment("? && ?", g.linked_assets, ^asset_identifiers) and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by linked debts.
  """
  def get_financial_goals_by_linked_debts(user, debt_identifiers) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: fragment("? && ?", g.linked_debts, ^debt_identifiers) and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by linked cash flows.
  """
  def get_financial_goals_by_linked_cash_flows(user, cash_flow_identifiers) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: fragment("? && ?", g.linked_cash_flows, ^cash_flow_identifiers) and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by milestone date.
  """
  def get_financial_goals_by_milestone_date(user, milestone_date) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.next_milestone_date == ^milestone_date and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by checkpoint date.
  """
  def get_financial_goals_by_checkpoint_date(user, checkpoint_date) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.next_checkpoint_date == ^checkpoint_date and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by recurrence pattern.
  """
  def get_financial_goals_by_recurrence_pattern(user, pattern) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.recurrence_pattern == ^pattern and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by notification status.
  """
  def get_financial_goals_by_notification_status(user, notifications_enabled) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.notifications_enabled == ^notifications_enabled and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by auto-adjust status.
  """
  def get_financial_goals_by_auto_adjust_status(user, auto_adjust_targets) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.auto_adjust_targets == ^auto_adjust_targets and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by recurring status.
  """
  def get_financial_goals_by_recurring_status(user, is_recurring) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.is_recurring == ^is_recurring and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by importance level.
  """
  def get_financial_goals_by_importance_level(user, importance_level) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.importance_level == ^importance_level and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by parent goal.
  """
  def get_financial_goals_by_parent_goal(user, parent_goal_id) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.parent_goal_id == ^parent_goal_id and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by created by.
  """
  def get_financial_goals_by_created_by(user, created_by) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.created_by == ^created_by and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by updated by.
  """
  def get_financial_goals_by_updated_by(user, updated_by) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.updated_by == ^updated_by and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by last updated date range.
  """
  def get_financial_goals_by_last_updated_range(user, start_date, end_date) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.last_updated_at >= ^start_date and g.last_updated_at <= ^end_date and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by start date range.
  """
  def get_financial_goals_by_start_date_range(user, start_date, end_date) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.start_date >= ^start_date and g.start_date <= ^end_date and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by created date range.
  """
  def get_financial_goals_by_created_date_range(user, start_date, end_date) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.inserted_at >= ^start_date and g.inserted_at <= ^end_date and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by updated date range.
  """
  def get_financial_goals_by_updated_date_range(user, start_date, end_date) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.updated_at >= ^start_date and g.updated_at <= ^end_date and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by monthly contribution target range.
  """
  def get_financial_goals_by_monthly_contribution_range(user, min_contribution, max_contribution) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.monthly_contribution_target >= ^min_contribution and g.monthly_contribution_target <= ^max_contribution and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by monthly contribution actual range.
  """
  def get_financial_goals_by_monthly_contribution_actual_range(user, min_contribution, max_contribution) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.monthly_contribution_actual >= ^min_contribution and g.monthly_contribution_actual <= ^max_contribution and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by current amount range.
  """
  def get_financial_goals_by_current_amount_range(user, min_amount, max_amount) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.current_amount >= ^min_amount and g.current_amount <= ^max_amount and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by goal identifier.
  """
  def get_financial_goal_by_identifier(user, goal_identifier) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.goal_identifier == ^goal_identifier and g.is_active == true)])
    |> Map.get(:financial_goals)
    |> List.first()
  end

  @doc """
  Gets user's financial goals by goal name.
  """
  def get_financial_goals_by_name(user, goal_name) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.goal_name == ^goal_name and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by goal subcategory.
  """
  def get_financial_goals_by_subcategory(user, goal_subcategory) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.goal_subcategory == ^goal_subcategory and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by XBRL concept identifier.
  """
  def get_financial_goals_by_xbrl_concept(user, xbrl_concept_identifier) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.xbrl_concept_identifier == ^xbrl_concept_identifier and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by XBRL context reference.
  """
  def get_financial_goals_by_xbrl_context(user, xbrl_context_ref) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.xbrl_context_ref == ^xbrl_context_ref and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's financial goals by XBRL unit reference.
  """
  def get_financial_goals_by_xbrl_unit(user, xbrl_unit_ref) do
    user
    |> Repo.preload([financial_goals: from(g in FinancialGoal, where: g.xbrl_unit_ref == ^xbrl_unit_ref and g.is_active == true)])
    |> Map.get(:financial_goals)
  end

  @doc """
  Gets user's assets.
  """
  def get_assets(user) do
    user
    |> Repo.preload([:assets])
    |> Map.get(:assets)
  end

  @doc """
  Gets user's active assets.
  """
  def get_active_assets(user) do
    user
    |> Repo.preload([assets: from(a in SoupAndNutz.FinancialInstruments.Asset, where: a.is_active == true)])
    |> Map.get(:assets)
  end

  @doc """
  Gets user's assets by type.
  """
  def get_assets_by_type(user, asset_type) do
    user
    |> Repo.preload([assets: from(a in SoupAndNutz.FinancialInstruments.Asset, where: a.asset_type == ^asset_type and a.is_active == true)])
    |> Map.get(:assets)
  end

  @doc """
  Gets user's debt obligations.
  """
  def get_debt_obligations(user) do
    user
    |> Repo.preload([:debt_obligations])
    |> Map.get(:debt_obligations)
  end

  @doc """
  Gets user's active debt obligations.
  """
  def get_active_debt_obligations(user) do
    user
    |> Repo.preload([debt_obligations: from(d in SoupAndNutz.FinancialInstruments.DebtObligation, where: d.is_active == true)])
    |> Map.get(:debt_obligations)
  end

  @doc """
  Gets user's debt obligations by type.
  """
  def get_debt_obligations_by_type(user, debt_type) do
    user
    |> Repo.preload([debt_obligations: from(d in SoupAndNutz.FinancialInstruments.DebtObligation, where: d.debt_type == ^debt_type and d.is_active == true)])
    |> Map.get(:debt_obligations)
  end

  @doc """
  Gets user's cash flows.
  """
  def get_cash_flows(user) do
    user
    |> Repo.preload([:cash_flows])
    |> Map.get(:cash_flows)
  end

  @doc """
  Gets user's active cash flows.
  """
  def get_active_cash_flows(user) do
    user
    |> Repo.preload([cash_flows: from(c in SoupAndNutz.FinancialInstruments.CashFlow, where: c.is_active == true)])
    |> Map.get(:cash_flows)
  end

  @doc """
  Gets user's cash flows by type.
  """
  def get_cash_flows_by_type(user, cash_flow_type) do
    user
    |> Repo.preload([cash_flows: from(c in SoupAndNutz.FinancialInstruments.CashFlow, where: c.cash_flow_type == ^cash_flow_type and c.is_active == true)])
    |> Map.get(:cash_flows)
  end

  @doc """
  Gets user's net worth snapshots.
  """
  def get_net_worth_snapshots(user) do
    user
    |> Repo.preload([:net_worth_snapshots])
    |> Map.get(:net_worth_snapshots)
  end

  @doc """
  Gets user's latest net worth snapshot.
  """
  def get_latest_net_worth_snapshot(user) do
    user
    |> Repo.preload([net_worth_snapshots: from(n in SoupAndNutz.FinancialInstruments.NetWorthSnapshot, order_by: [desc: n.snapshot_date], limit: 1)])
    |> Map.get(:net_worth_snapshots)
    |> List.first()
  end

  # Private validation functions

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/, message: "must contain only letters, numbers, and underscores")
    |> validate_length(:username, min: 3, max: 30)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 80)
    |> validate_confirmation(:password, message: "does not match password")
  end

  defp validate_financial_preferences(changeset) do
    changeset
    |> validate_inclusion(:preferred_currency, ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "CHF", "CNY"])
    |> validate_inclusion(:default_reporting_period, ["Daily", "Weekly", "Monthly", "Quarterly", "Annual"])
    |> validate_inclusion(:risk_tolerance, ["Low", "Medium", "High"])
    |> validate_inclusion(:investment_horizon, ["ShortTerm", "MediumTerm", "LongTerm"])
    |> validate_inclusion(:privacy_level, ["Public", "Private", "Shared"])
    |> validate_inclusion(:account_type, ["Individual", "Family", "Business"])
    |> validate_inclusion(:subscription_tier, ["Free", "Basic", "Premium", "Enterprise"])
  end

  defp validate_profile_data(changeset) do
    changeset
    |> validate_length(:first_name, max: 50)
    |> validate_length(:last_name, max: 50)
    |> validate_length(:phone_number, max: 20)
    |> validate_length(:timezone, max: 50)
    |> validate_length(:locale, max: 10)
    |> validate_length(:notes, max: 1000)
  end

  defp validate_subscription_data(changeset) do
    changeset
    |> validate_inclusion(:subscription_tier, ["Free", "Basic", "Premium", "Enterprise"])
  end

  defp put_password_hash(changeset) do
    if password = get_change(changeset, :password) do
      change(changeset, password_hash: Bcrypt.hash_pwd_salt(password))
    else
      changeset
    end
  end
end
