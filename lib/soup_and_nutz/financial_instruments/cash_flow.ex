defmodule SoupAndNutz.FinancialInstruments.CashFlow do
  @moduledoc """
  Schema and business logic for cash flows in the financial instruments system.

  This module manages income and expense transactions, supporting both one-time
  and recurring cash flows. It includes budgeting features and follows XBRL
  reporting standards for financial data consistency.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias SoupAndNutz.XBRL.Concepts

  schema "cash_flows" do
    # XBRL-inspired identifier fields
    field :cash_flow_identifier, :string  # Unique identifier for the cash flow
    field :cash_flow_name, :string       # Human-readable name
    field :cash_flow_type, :string       # "Income" or "Expense"
    field :cash_flow_category, :string   # Main category (e.g., "Salary", "Housing")
    field :cash_flow_subcategory, :string # Sub-category (e.g., "Base Salary", "Rent")

    # Financial measurement fields
    field :amount, :decimal              # Transaction amount
    field :currency_code, :string        # ISO currency code
    field :transaction_date, :date       # When the transaction occurred
    field :effective_date, :date         # When the transaction takes effect

    # XBRL context fields
    field :reporting_period, :string     # e.g., "2024-12", "2024-Q4"
    field :reporting_entity, :string     # Entity identifier
    field :reporting_scenario, :string   # "Actual", "Budget", "Forecast"

    # Cash flow specific fields
    field :frequency, :string            # "OneTime", "Monthly", "Quarterly", "Annual"
    field :is_recurring, :boolean, default: false
    field :recurrence_pattern, :string   # "Daily", "Weekly", "Monthly", "Quarterly", "Annual"
    field :next_occurrence_date, :date
    field :end_date, :date               # For recurring transactions

    # Source and destination tracking
    field :source_account, :string       # Bank account, credit card, etc.
    field :destination_account, :string
    field :payment_method, :string       # "Cash", "Check", "CreditCard", "BankTransfer", "Digital"

    # Budget and planning fields
    field :budgeted_amount, :decimal     # Planned amount for budget period
    field :budget_period, :string        # "Monthly", "Quarterly", "Annual"
    field :is_budget_item, :boolean, default: false
    field :budget_category, :string

    # Additional metadata
    field :description, :string
    field :notes, :string
    field :tags, {:array, :string}       # For flexible categorization
    field :is_active, :boolean, default: true
    field :is_tax_deductible, :boolean, default: false
    field :tax_category, :string         # For tax planning

    # Priority and importance
    field :priority_level, :string       # "Critical", "High", "Medium", "Low"
    field :importance_level, :string     # "Essential", "Important", "NiceToHave", "Luxury"

    # XBRL validation fields
    field :validation_status, :string, default: "Pending"
    field :last_validated_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cash_flow, attrs) do
    cash_flow
    |> cast(attrs, [
      :cash_flow_identifier, :cash_flow_name, :cash_flow_type, :cash_flow_category, :cash_flow_subcategory,
      :amount, :currency_code, :transaction_date, :effective_date,
      :reporting_period, :reporting_entity, :reporting_scenario,
      :frequency, :is_recurring, :recurrence_pattern, :next_occurrence_date, :end_date,
      :source_account, :destination_account, :payment_method,
      :budgeted_amount, :budget_period, :is_budget_item, :budget_category,
      :description, :notes, :tags, :is_active, :is_tax_deductible, :tax_category,
      :priority_level, :importance_level, :validation_status, :last_validated_at
    ])
    |> validate_required([
      :cash_flow_identifier, :cash_flow_name, :cash_flow_type, :cash_flow_category,
      :amount, :currency_code, :transaction_date, :effective_date,
      :reporting_period, :reporting_entity
    ])
    |> validate_inclusion(:cash_flow_type, Concepts.cash_flow_types())
    |> validate_inclusion(:currency_code, Concepts.currency_codes())
    |> validate_inclusion(:frequency, Concepts.cash_flow_frequencies())
    |> validate_inclusion(:payment_method, Concepts.payment_methods())
    |> validate_inclusion(:priority_level, Concepts.priority_levels())
    |> validate_inclusion(:importance_level, Concepts.importance_levels())
    |> validate_inclusion(:validation_status, Concepts.validation_statuses())
    |> validate_inclusion(:budget_period, Concepts.budget_periods())
    |> validate_inclusion(:tax_category, Concepts.tax_categories())
    |> validate_number(:amount, greater_than: 0)
    |> validate_number(:budgeted_amount, greater_than_or_equal_to: 0)
    |> unique_constraint(:cash_flow_identifier)
    |> validate_format(:cash_flow_identifier, ~r/^[A-Z0-9_-]+$/, message: "must contain only uppercase letters, numbers, underscores, and hyphens")
    |> validate_dates()
    |> validate_recurring_fields()
  end

  @doc """
  Returns a list of valid cash flow types.
  """
  def cash_flow_types, do: Concepts.cash_flow_types()

  @doc """
  Returns a list of valid cash flow categories.
  """
  def cash_flow_categories, do: Concepts.cash_flow_categories()

  @doc """
  Returns a list of valid cash flow frequencies.
  """
  def cash_flow_frequencies, do: Concepts.cash_flow_frequencies()

  @doc """
  Returns a list of valid payment methods.
  """
  def payment_methods, do: Concepts.payment_methods()

  @doc """
  Returns a list of valid importance levels.
  """
  def importance_levels, do: Concepts.importance_levels()

  @doc """
  Returns a list of valid budget periods.
  """
  def budget_periods, do: Concepts.budget_periods()

  @doc """
  Returns a list of valid tax categories.
  """
  def tax_categories, do: Concepts.tax_categories()

  @doc """
  Calculates total income for a given period and entity.
  """
  def total_income(cash_flows, period, entity, currency \\ "USD") do
    cash_flows
    |> Enum.filter(&(&1.cash_flow_type == "Income" &&
                     &1.reporting_period == period &&
                     &1.reporting_entity == entity &&
                     &1.currency_code == currency &&
                     &1.is_active))
    |> Enum.reduce(Decimal.new(0), fn cash_flow, acc ->
      Decimal.add(acc, cash_flow.amount)
    end)
  end

  @doc """
  Calculates total expenses for a given period and entity.
  """
  def total_expenses(cash_flows, period, entity, currency \\ "USD") do
    cash_flows
    |> Enum.filter(&(&1.cash_flow_type == "Expense" &&
                     &1.reporting_period == period &&
                     &1.reporting_entity == entity &&
                     &1.currency_code == currency &&
                     &1.is_active))
    |> Enum.reduce(Decimal.new(0), fn cash_flow, acc ->
      Decimal.add(acc, cash_flow.amount)
    end)
  end

  @doc """
  Calculates net cash flow (income - expenses) for a given period and entity.
  """
  def net_cash_flow(cash_flows, period, entity, currency \\ "USD") do
    income = total_income(cash_flows, period, entity, currency)
    expenses = total_expenses(cash_flows, period, entity, currency)
    Decimal.sub(income, expenses)
  end

  @doc """
  Groups cash flows by category for analysis.
  """
  def group_by_category(cash_flows, type \\ nil) do
    cash_flows
    |> Enum.filter(fn cf ->
      if type, do: cf.cash_flow_type == type, else: true
    end)
    |> Enum.group_by(& &1.cash_flow_category)
    |> Enum.map(fn {category, category_flows} ->
      total_amount = Enum.reduce(category_flows, Decimal.new(0), fn flow, acc ->
        Decimal.add(acc, flow.amount)
      end)
      {category, %{flows: category_flows, total: total_amount}}
    end)
    |> Enum.sort_by(fn {_category, %{total: total}} -> total end, :desc)
  end

  @doc """
  Validates cash flow data according to business rules.
  """
  def validate_cash_flow_rules(cash_flow) do
    errors = []

    # Validate that income amounts are positive
    errors = if cash_flow.cash_flow_type == "Income" && Decimal.lt?(cash_flow.amount, Decimal.new(0)) do
      [{"amount", "Income amounts must be positive"} | errors]
    else
      errors
    end

    # Validate that expense amounts are positive
    errors = if cash_flow.cash_flow_type == "Expense" && Decimal.lt?(cash_flow.amount, Decimal.new(0)) do
      [{"amount", "Expense amounts must be positive"} | errors]
    else
      errors
    end

    # Validate recurring transaction dates
    errors = if cash_flow.is_recurring && cash_flow.next_occurrence_date do
      if Date.compare(cash_flow.next_occurrence_date, cash_flow.transaction_date) == :lt do
        [{"next_occurrence_date", "Next occurrence date cannot be before transaction date"} | errors]
      else
        errors
      end
    else
      errors
    end

    # Validate budget amounts
    errors = if cash_flow.budgeted_amount && cash_flow.amount do
      if Decimal.lt?(cash_flow.budgeted_amount, Decimal.new(0)) do
        [{"budgeted_amount", "Budgeted amount cannot be negative"} | errors]
      else
        errors
      end
    else
      errors
    end

    {Enum.empty?(errors), errors}
  end

  # Private validation functions

  defp validate_dates(changeset) do
    case {get_field(changeset, :effective_date), get_field(changeset, :transaction_date)} do
      {effective_date, transaction_date} when not is_nil(effective_date) and not is_nil(transaction_date) ->
        if Date.compare(effective_date, transaction_date) == :lt do
          add_error(changeset, :effective_date, "Effective date cannot be before transaction date")
        else
          changeset
        end
      _ -> changeset
    end
  end

  defp validate_recurring_fields(changeset) do
    case get_field(changeset, :is_recurring) do
      true ->
        changeset
        |> validate_required([:recurrence_pattern, :next_occurrence_date])
        |> validate_inclusion(:recurrence_pattern, Concepts.cash_flow_frequencies())
      _ -> changeset
    end
  end
end
