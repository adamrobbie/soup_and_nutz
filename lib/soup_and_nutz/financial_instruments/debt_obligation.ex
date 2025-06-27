defmodule SoupAndNutz.FinancialInstruments.DebtObligation do
  @moduledoc """
  Schema and business logic for debt obligations in the financial instruments system.

  This module manages debt obligations such as loans, mortgages, credit cards, and other
  liabilities. It follows XBRL reporting standards for financial data consistency and
  includes validation for debt-specific business rules.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias SoupAndNutz.XBRL.Concepts

  schema "debt_obligations" do
    # User association
    belongs_to :user, SoupAndNutz.Accounts.User

    # XBRL-inspired identifier fields
    field :debt_identifier, :string    # Unique identifier for the debt obligation
    field :debt_name, :string         # Human-readable name
    field :debt_type, :string         # Classification from Concepts.debt_types
    field :debt_category, :string     # Sub-category within type

    # Financial measurement fields (following XBRL measurement concepts)
    field :principal_amount, :decimal # Original principal amount
    field :outstanding_balance, :decimal # Current outstanding balance
    field :interest_rate, :decimal    # Annual interest rate (percentage)
    field :currency_code, :string     # ISO currency code
    field :measurement_date, :date    # Date of measurement

    # XBRL context fields
    field :reporting_period, :string  # e.g., "2024-12-31"
    field :reporting_scenario, :string # e.g., "Actual", "Budget", "Forecast"

    # Debt-specific fields
    field :lender_name, :string       # Name of the lender
    field :account_number, :string    # Account number with lender
    field :maturity_date, :date       # When debt matures
    field :payment_frequency, :string # How often payments are made
    field :monthly_payment, :decimal  # Regular payment amount
    field :next_payment_date, :date   # Next payment due date

    # Additional metadata
    field :description, :string
    field :is_active, :boolean, default: true
    field :is_secured, :boolean, default: false
    field :collateral_description, :string
    field :risk_level, :string        # Low, Medium, High
    field :priority_level, :string    # High, Medium, Low (for repayment priority)

    # XBRL validation fields
    field :validation_status, :string, default: "Pending" # Pending, Valid, Invalid
    field :last_validated_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(debt_obligation, attrs) do
    debt_obligation
    |> cast(attrs, [
      :user_id, :debt_identifier, :debt_name, :debt_type, :debt_category,
      :principal_amount, :outstanding_balance, :interest_rate, :currency_code, :measurement_date,
      :reporting_period, :reporting_scenario,
      :lender_name, :account_number, :maturity_date, :payment_frequency,
      :monthly_payment, :next_payment_date, :description, :is_active,
      :is_secured, :collateral_description, :risk_level, :priority_level,
      :validation_status, :last_validated_at
    ])
    |> validate_required([
      :user_id, :debt_identifier, :debt_name, :debt_type, :currency_code,
      :measurement_date, :reporting_period
    ])
    |> validate_inclusion(:debt_type, Concepts.debt_types())
    |> validate_inclusion(:currency_code, Concepts.currency_codes())
    |> validate_inclusion(:payment_frequency, Concepts.payment_frequencies())
    |> validate_inclusion(:risk_level, Concepts.risk_levels())
    |> validate_inclusion(:priority_level, Concepts.priority_levels())
    |> validate_inclusion(:validation_status, Concepts.validation_statuses())
    |> validate_number(:principal_amount, greater_than: 0)
    |> validate_number(:outstanding_balance, greater_than_or_equal_to: 0)
    |> validate_number(:interest_rate, greater_than_or_equal_to: 0)
    |> validate_number(:monthly_payment, greater_than_or_equal_to: 0)
    |> unique_constraint(:debt_identifier)
    |> validate_format(:debt_identifier, ~r/^[A-Z0-9_-]+$/, message: "must contain only uppercase letters, numbers, underscores, and hyphens")
    |> validate_maturity_date()
    |> validate_outstanding_balance()
  end

  @doc """
  Returns a list of valid debt types for form selection.
  """
  def debt_types, do: Concepts.debt_types()

  @doc """
  Returns a list of valid currency codes for form selection.
  """
  def currency_codes, do: Concepts.currency_codes()

  @doc """
  Returns a list of valid payment frequencies for form selection.
  """
  def payment_frequencies, do: Concepts.payment_frequencies()

  @doc """
  Calculates the total outstanding debt in a given currency.
  """
  def total_outstanding_debt(debts, currency \\ "USD") do
    debts
    |> Enum.filter(&(&1.currency_code == currency))
    |> Enum.reduce(Decimal.new(0), fn debt, acc ->
      Decimal.add(acc, debt.outstanding_balance || Decimal.new(0))
    end)
  end

  @doc """
  Calculates the total monthly debt payments.
  """
  def total_monthly_payments(debts, currency \\ "USD") do
    debts
    |> Enum.filter(&(&1.currency_code == currency))
    |> Enum.reduce(Decimal.new(0), fn debt, acc ->
      monthly_payment = debt.monthly_payment || Decimal.new(0)
      Decimal.add(acc, monthly_payment)
    end)
  end

  @doc """
  Validates debt obligation data according to XBRL business rules.
  """
  def validate_xbrl_rules(debt_obligation) do
    errors = []

    errors = if debt_obligation.outstanding_balance && debt_obligation.principal_amount do
      if Decimal.gt?(debt_obligation.outstanding_balance, debt_obligation.principal_amount) do
        [{"outstanding_balance", "Outstanding balance cannot exceed principal amount"} | errors]
      else
        errors
      end
    else
      errors
    end

    errors = if debt_obligation.maturity_date && debt_obligation.is_active do
      if Date.compare(debt_obligation.maturity_date, Date.utc_today()) == :lt do
        [{"maturity_date", "Maturity date should be in the future for active debts"} | errors]
      else
        errors
      end
    else
      errors
    end

    errors = if debt_obligation.interest_rate do
      if Decimal.gt?(debt_obligation.interest_rate, Decimal.new("50")) do
        [{"interest_rate", "Interest rate seems unusually high"} | errors]
      else
        errors
      end
    else
      errors
    end

    {Enum.empty?(errors), errors}
  end

  # Private validation functions
  defp validate_maturity_date(changeset) do
    maturity_date = get_field(changeset, :maturity_date)
    measurement_date = get_field(changeset, :measurement_date)

    validate_dates(changeset, maturity_date, measurement_date)
  end

  defp validate_dates(changeset, nil, _), do: changeset
  defp validate_dates(changeset, _, nil), do: changeset
  defp validate_dates(changeset, maturity_date, measurement_date) do
    if Date.compare(maturity_date, measurement_date) == :lt do
      add_error(changeset, :maturity_date, "Maturity date cannot be before measurement date")
    else
      changeset
    end
  end

  defp validate_outstanding_balance(changeset) do
    case {get_field(changeset, :outstanding_balance), get_field(changeset, :principal_amount)} do
      {outstanding, principal} when not is_nil(outstanding) and not is_nil(principal) ->
        if Decimal.gt?(outstanding, principal) do
          add_error(changeset, :outstanding_balance, "Outstanding balance cannot exceed principal amount")
        else
          changeset
        end
      _ -> changeset
    end
  end
end
