defmodule SoupAndNutz.FinancialInstruments.NetWorthSnapshot do
  @moduledoc """
  Represents a snapshot of net worth at a specific point in time.
  This enables historical tracking and trend analysis of financial position.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Decimal, as: D
  alias SoupAndNutz.Repo

  schema "net_worth_snapshots" do
    # User association
    belongs_to :user, SoupAndNutz.Accounts.User

    field :snapshot_date, :date
    field :reporting_period, :string
    field :currency_code, :string, default: "USD"

    # Net worth components
    field :total_assets, :decimal
    field :total_liabilities, :decimal
    field :net_worth, :decimal

    # Cash flow integration
    field :monthly_income, :decimal
    field :monthly_expenses, :decimal
    field :net_monthly_cash_flow, :decimal
    field :savings_rate, :decimal

    # Financial health metrics
    field :debt_to_asset_ratio, :decimal
    field :debt_to_income_ratio, :decimal
    field :liquidity_ratio, :decimal
    field :emergency_fund_ratio, :decimal

    # Risk and stability scores
    field :risk_score, :decimal
    field :financial_stability_score, :decimal

    # Projections
    field :projected_net_worth_12m, :decimal
    field :projected_net_worth_24m, :decimal
    field :projected_net_worth_60m, :decimal

    # Metadata
    field :snapshot_type, Ecto.Enum, values: [:monthly, :quarterly, :annual, :manual]
    field :is_active, :boolean, default: true
    field :notes, :string

    # XBRL compliance
    field :xbrl_concept_identifier, :string
    field :xbrl_context_ref, :string
    field :xbrl_unit_ref, :string

    timestamps()
  end

  @doc false
  def changeset(net_worth_snapshot, attrs) do
    net_worth_snapshot
    |> cast(attrs, [
      :user_id, :snapshot_date, :reporting_period, :currency_code,
      :total_assets, :total_liabilities, :net_worth,
      :monthly_income, :monthly_expenses, :net_monthly_cash_flow, :savings_rate,
      :debt_to_asset_ratio, :debt_to_income_ratio, :liquidity_ratio, :emergency_fund_ratio,
      :risk_score, :financial_stability_score,
      :projected_net_worth_12m, :projected_net_worth_24m, :projected_net_worth_60m,
      :snapshot_type, :is_active, :notes,
      :xbrl_concept_identifier, :xbrl_context_ref, :xbrl_unit_ref
    ])
    |> validate_required([
      :user_id, :snapshot_date, :reporting_period, :currency_code,
      :total_assets, :total_liabilities, :net_worth
    ])
    |> validate_net_worth_consistency()
    |> validate_financial_ratios()
    |> validate_xbrl_compliance()
    |> unique_constraint([:snapshot_date, :user_id, :snapshot_type])
  end

  @doc """
  Creates a net worth snapshot from comprehensive financial data.
  """
  def create_snapshot_from_data(user_id, period, currency \\ "USD") do
    alias SoupAndNutz.FinancialAnalysis
    alias SoupAndNutz.FinancialInstruments

    # Get comprehensive financial report
    report = FinancialInstruments.generate_comprehensive_net_worth_report(user_id, period, currency)

    # Calculate projections
    projections_12m = FinancialAnalysis.calculate_net_worth(user_id, period, currency, 12)
    projections_24m = FinancialAnalysis.calculate_net_worth(user_id, period, currency, 24)
    projections_60m = FinancialAnalysis.calculate_net_worth(user_id, period, currency, 60)

    attrs = %{
      user_id: user_id,
      snapshot_date: Date.utc_today(),
      reporting_period: period,
      currency_code: currency,

      # Net worth components
      total_assets: report.total_assets,
      total_liabilities: report.total_debt,
      net_worth: report.current_net_worth,

      # Cash flow integration
      monthly_income: report.monthly_income,
      monthly_expenses: report.monthly_expenses,
      net_monthly_cash_flow: report.net_monthly_cash_flow,
      savings_rate: report.savings_rate,

      # Financial ratios
      debt_to_asset_ratio: report.debt_to_asset_ratio,
      debt_to_income_ratio: report.debt_to_income_ratio,
      liquidity_ratio: report.liquidity_ratio,
      emergency_fund_ratio: report.emergency_fund_ratio,

      # Risk scores
      risk_score: report.risk_score,
      financial_stability_score: report.financial_stability_score,

      # Projections
      projected_net_worth_12m: projections_12m.projected_net_worth,
      projected_net_worth_24m: projections_24m.projected_net_worth,
      projected_net_worth_60m: projections_60m.projected_net_worth,

      # Metadata
      snapshot_type: :monthly,
      notes: "Auto-generated snapshot from comprehensive financial analysis"
    }

    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Retrieves net worth history for trend analysis.
  """
  def get_net_worth_history(user_id, start_date, end_date, currency \\ "USD") do
    NetWorthSnapshot
    |> where([n], n.user_id == ^user_id and
                n.currency_code == ^currency and
                n.is_active == true and
                n.snapshot_date >= ^start_date and
                n.snapshot_date <= ^end_date)
    |> order_by([n], [asc: n.snapshot_date])
    |> Repo.all()
  end

  @doc """
  Calculates net worth growth rate over a period.
  """
  def calculate_growth_rate(user_id, start_date, end_date, currency \\ "USD") do
    history = get_net_worth_history(user_id, start_date, end_date, currency)

    if length(history) < 2 do
      {:error, "Insufficient data for growth rate calculation"}
    else
      [first | _] = history
      [last | _] = Enum.reverse(history)

      net_worth_change = D.sub(last.net_worth, first.net_worth)

      growth_rate = if D.eq?(first.net_worth, D.new("0")) do
        D.new("0")
      else
        D.mult(D.div(net_worth_change, first.net_worth), D.new("100"))
      end

      {:ok, %{
        start_net_worth: first.net_worth,
        end_net_worth: last.net_worth,
        net_worth_change: net_worth_change,
        growth_rate: growth_rate,
        periods_analyzed: length(history),
        average_monthly_growth: D.div(growth_rate, D.new(length(history)))
      }}
    end
  end

  @doc """
  Analyzes net worth volatility and stability.
  """
  def analyze_volatility(user_id, start_date, end_date, currency \\ "USD") do
    history = get_net_worth_history(user_id, start_date, end_date, currency)

    if length(history) < 3 do
      {:error, "Insufficient data for volatility analysis"}
    else
      net_worth_values = Enum.map(history, & &1.net_worth)

      # Calculate monthly changes
      changes = calculate_monthly_changes(net_worth_values)

      # Calculate volatility metrics
      mean_change = calculate_mean(changes)
      variance = calculate_variance(changes, mean_change)
      standard_deviation = D.sqrt(variance)

      # Calculate coefficient of variation
      mean_net_worth = calculate_mean(net_worth_values)
      coefficient_of_variation = if D.eq?(mean_net_worth, D.new("0")) do
        D.new("0")
      else
        D.div(standard_deviation, mean_net_worth)
      end

      {:ok, %{
        mean_monthly_change: mean_change,
        standard_deviation: standard_deviation,
        coefficient_of_variation: coefficient_of_variation,
        volatility_score: calculate_volatility_score(coefficient_of_variation),
        periods_analyzed: length(history),
        max_monthly_gain: Enum.max(changes),
        max_monthly_loss: Enum.min(changes)
      }}
    end
  end

  @doc """
  Validates XBRL compliance for net worth snapshots.
  """
  def validate_xbrl_rules(snapshot) do
    errors = []

    # Check required XBRL fields
    if is_nil(snapshot.xbrl_concept_identifier) do
      errors = [{"xbrl_concept_identifier", "XBRL concept identifier is required"} | errors]
    end

    if is_nil(snapshot.xbrl_context_ref) do
      errors = [{"xbrl_context_ref", "XBRL context reference is required"} | errors]
    end

    # Validate currency code format
    unless snapshot.currency_code in ["USD", "EUR", "GBP", "CAD", "AUD"] do
      errors = [{"currency_code", "Invalid currency code"} | errors]
    end

    {Enum.empty?(errors), errors}
  end

  # Private helper functions

  defp validate_net_worth_consistency(changeset) do
    total_assets = get_field(changeset, :total_assets)
    total_liabilities = get_field(changeset, :total_liabilities)
    net_worth = get_field(changeset, :net_worth)

    if total_assets && total_liabilities && net_worth do
      calculated_net_worth = D.sub(total_assets, total_liabilities)

      if D.eq?(calculated_net_worth, net_worth) do
        changeset
      else
        add_error(changeset, :net_worth, "Net worth must equal total assets minus total liabilities")
      end
    else
      changeset
    end
  end

  defp validate_financial_ratios(changeset) do
    # Validate that ratios are within reasonable bounds
    ratios = [
      {:debt_to_asset_ratio, 0, 2},
      {:debt_to_income_ratio, 0, 1000}, # Can be high when no debt or very low income
      {:liquidity_ratio, 0, 100},
      {:emergency_fund_ratio, 0, 100},
      {:savings_rate, -100, 100},
      {:risk_score, 1, 10},
      {:financial_stability_score, 1, 10}
    ]

    Enum.reduce(ratios, changeset, fn {field, min_val, max_val}, acc ->
      value = get_field(acc, field)
      if value && (D.lt?(value, D.new(min_val)) or D.gt?(value, D.new(max_val))) do
        add_error(acc, field, "Value must be between #{min_val} and #{max_val}")
      else
        acc
      end
    end)
  end

  defp validate_xbrl_compliance(changeset) do
    snapshot = apply_changes(changeset)
    {valid, errors} = validate_xbrl_rules(snapshot)

    if valid do
      changeset
    else
      Enum.reduce(errors, changeset, fn {field, message}, acc ->
        add_error(acc, field, message)
      end)
    end
  end

  defp calculate_monthly_changes(values) do
    values
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [prev, curr] -> D.sub(curr, prev) end)
  end

  defp calculate_mean(values) do
    sum = Enum.reduce(values, D.new("0"), &D.add(&2, &1))
    D.div(sum, D.new(length(values)))
  end

  defp calculate_variance(values, mean) do
    squared_diffs = Enum.map(values, fn value ->
      diff = D.sub(value, mean)
      D.mult(diff, diff)
    end)

    sum_squared_diffs = Enum.reduce(squared_diffs, D.new("0"), &D.add(&2, &1))
    D.div(sum_squared_diffs, D.new(length(values)))
  end

  defp calculate_volatility_score(coefficient_of_variation) do
    cond do
      D.lt?(coefficient_of_variation, D.new("0.1")) -> "Low"
      D.lt?(coefficient_of_variation, D.new("0.25")) -> "Medium"
      true -> "High"
    end
  end
end
