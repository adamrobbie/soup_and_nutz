defmodule SoupAndNutz.FinancialInstruments do
  @moduledoc """
  The FinancialInstruments context provides business logic for managing
  assets and debt obligations using XBRL-inspired standards.
  """

  import Ecto.Query, warn: false

  alias SoupAndNutz.FinancialInstruments.{Asset, CashFlow, DebtObligation}
  alias SoupAndNutz.Repo
  alias SoupAndNutz.AI.EmbeddingService

  # Asset functions

  @doc """
  Returns the list of assets.
  """
  def list_assets do
    Repo.all(Asset)
  end

  @doc """
  Returns the list of assets for a specific user (XBRL: reporting_entity is retained for context, but user_id is primary).
  """
  def list_assets_by_user(user_id) do
    Asset
    |> where([a], a.user_id == ^user_id and a.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets a single asset by ID.
  """
  def get_asset!(id), do: Repo.get!(Asset, id)

  @doc """
  Gets a single asset by identifier.
  """
  def get_asset_by_identifier(identifier) do
    Repo.get_by(Asset, asset_identifier: identifier)
  end

  @doc """
  Creates an asset and generates its embedding.
  """
  def create_asset(attrs \\ %{}) do
    %Asset{}
    |> Asset.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, asset} ->
        # Generate embedding asynchronously if enabled
        if Application.get_env(:soup_and_nutz, :enable_embeddings, true) do
          Task.start(fn -> EmbeddingService.update_asset_embedding(asset) end)
        end
        {:ok, asset}
      error -> error
    end
  end

  @doc """
  Updates an asset and regenerates its embedding.
  """
  def update_asset(%Asset{} = asset, attrs) do
    asset
    |> Asset.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_asset} ->
        # Regenerate embedding asynchronously if enabled
        if Application.get_env(:soup_and_nutz, :enable_embeddings, true) do
          Task.start(fn -> EmbeddingService.update_asset_embedding(updated_asset) end)
        end
        {:ok, updated_asset}
      error -> error
    end
  end

  @doc """
  Deletes an asset.
  """
  def delete_asset(%Asset{} = asset) do
    Repo.delete(asset)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking asset changes.
  """
  def change_asset(%Asset{} = asset, attrs \\ %{}) do
    Asset.changeset(asset, attrs)
  end

  # Debt Obligation functions

  @doc """
  Returns the list of debt obligations.
  """
  def list_debt_obligations do
    Repo.all(DebtObligation)
  end

  @doc """
  Returns the list of debt obligations for a specific user (XBRL: reporting_entity is retained for context, but user_id is primary).
  """
  def list_debt_obligations_by_user(user_id) do
    DebtObligation
    |> where([d], d.user_id == ^user_id and d.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets a single debt obligation by ID.
  """
  def get_debt_obligation!(id), do: Repo.get!(DebtObligation, id)

  @doc """
  Gets a single debt obligation by identifier.
  """
  def get_debt_obligation_by_identifier(identifier) do
    Repo.get_by(DebtObligation, debt_identifier: identifier)
  end

  @doc """
  Creates a debt obligation and generates its embedding.
  """
  def create_debt_obligation(attrs \\ %{}) do
    %DebtObligation{}
    |> DebtObligation.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, debt} ->
        # Generate embedding asynchronously if enabled
        if Application.get_env(:soup_and_nutz, :enable_embeddings, true) do
          Task.start(fn -> EmbeddingService.update_debt_embedding(debt) end)
        end
        {:ok, debt}
      error -> error
    end
  end

  @doc """
  Updates a debt obligation and regenerates its embedding.
  """
  def update_debt_obligation(%DebtObligation{} = debt, attrs) do
    debt
    |> DebtObligation.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_debt} ->
        # Regenerate embedding asynchronously if enabled
        if Application.get_env(:soup_and_nutz, :enable_embeddings, true) do
          Task.start(fn -> EmbeddingService.update_debt_embedding(updated_debt) end)
        end
        {:ok, updated_debt}
      error -> error
    end
  end

  @doc """
  Deletes a debt obligation.
  """
  def delete_debt_obligation(%DebtObligation{} = debt_obligation) do
    Repo.delete(debt_obligation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking debt obligation changes.
  """
  def change_debt_obligation(%DebtObligation{} = debt_obligation, attrs \\ %{}) do
    DebtObligation.changeset(debt_obligation, attrs)
  end

  # Cash Flow functions

  @doc """
  Returns the list of cash flows.
  """
  def list_cash_flows do
    Repo.all(CashFlow)
  end

  @doc """
  Returns the list of cash flows for a specific user (XBRL: reporting_entity is retained for context, but user_id is primary).
  """
  def list_cash_flows_by_user(user_id) do
    CashFlow
    |> where([c], c.user_id == ^user_id and c.is_active == true)
    |> Repo.all()
  end

  @doc """
  Returns the list of cash flows for a specific user and period (XBRL: reporting_entity is retained for context, but user_id is primary).
  """
  def list_cash_flows_by_user_and_period(user_id, period) do
    CashFlow
    |> where([c], c.user_id == ^user_id and c.reporting_period == ^period and c.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets a single cash flow by ID.
  """
  def get_cash_flow!(id), do: Repo.get!(CashFlow, id)

  @doc """
  Gets a single cash flow by identifier.
  """
  def get_cash_flow_by_identifier(identifier) do
    Repo.get_by(CashFlow, cash_flow_identifier: identifier)
  end

  @doc """
  Creates a cash flow with XBRL validation.
  """
  def create_cash_flow(attrs \\ %{}) do
    %CashFlow{}
    |> CashFlow.changeset(attrs)
    |> validate_cash_flow_xbrl_rules()
    |> Repo.insert()
  end

  @doc """
  Updates a cash flow with XBRL validation.
  """
  def update_cash_flow(%CashFlow{} = cash_flow, attrs) do
    cash_flow
    |> CashFlow.changeset(attrs)
    |> validate_cash_flow_xbrl_rules()
    |> Repo.update()
  end

  @doc """
  Deletes a cash flow.
  """
  def delete_cash_flow(%CashFlow{} = cash_flow) do
    Repo.delete(cash_flow)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cash flow changes.
  """
  def change_cash_flow(%CashFlow{} = cash_flow, attrs \\ %{}) do
    CashFlow.changeset(cash_flow, attrs)
  end

  @doc """
  Generates a cash flow report for a given user and period.
  """
  def generate_cash_flow_report(user_id, period, currency \\ "USD") do
    cash_flows = list_cash_flows_by_user_and_period(user_id, period)

    total_income = CashFlow.total_income(cash_flows, period, user_id, currency)
    total_expenses = CashFlow.total_expenses(cash_flows, period, user_id, currency)
    net_cash_flow = CashFlow.net_cash_flow(cash_flows, period, user_id, currency)

    %{
      user_id: user_id,
      reporting_period: period,
      currency: currency,
      total_income: total_income,
      total_expenses: total_expenses,
      net_cash_flow: net_cash_flow,
      savings_rate: calculate_savings_rate(total_income, total_expenses),
      income_by_category: CashFlow.group_by_category(cash_flows, "Income"),
      expenses_by_category: CashFlow.group_by_category(cash_flows, "Expense"),
      recurring_income: filter_recurring_cash_flows(cash_flows, "Income"),
      recurring_expenses: filter_recurring_cash_flows(cash_flows, "Expense")
    }
  end

  # Financial reporting functions

  @doc """
  Generates a comprehensive financial position report for a given user and period.
  """
  def generate_financial_position_report(user_id, period, currency \\ "USD") do
    assets = get_assets_by_user_and_period(user_id, period)
    debts = get_debts_by_user_and_period(user_id, period)

    total_assets = Asset.total_fair_value(assets, currency)
    total_debt = DebtObligation.total_outstanding_debt(debts, currency)
    net_worth = Decimal.sub(total_assets, total_debt)

    %{
      user_id: user_id,
      reporting_period: period,
      currency: currency,
      total_assets: total_assets,
      total_debt: total_debt,
      net_worth: net_worth,
      debt_to_asset_ratio: calculate_debt_to_asset_ratio(total_debt, total_assets),
      assets_by_type: group_assets_by_type(assets),
      debts_by_type: group_debts_by_type(debts),
      monthly_debt_payments: DebtObligation.total_monthly_payments(debts, currency)
    }
  end

  @doc """
  Generates a comprehensive net worth report integrating assets, liabilities, and cash flows.
  """
  def generate_comprehensive_net_worth_report(user_id, period, currency \\ "USD") do
    alias SoupAndNutz.FinancialAnalysis

    # Get basic financial position
    position_report = generate_financial_position_report(user_id, period, currency)

    # Get cash flow analysis
    cash_flow_report = generate_cash_flow_report(user_id, period, currency)

    # Get comprehensive financial health analysis
    health_report = FinancialAnalysis.generate_financial_health_report(user_id, period, currency)

    # Get projected net worth
    net_worth_projection = FinancialAnalysis.calculate_net_worth(user_id, period, currency, 12)

    # Get cash flow impact analysis
    cash_flow_impact = FinancialAnalysis.analyze_cash_flow_impact(user_id, period, currency, 12)

    # Get financial ratios
    financial_ratios = FinancialAnalysis.calculate_financial_ratios(user_id, period, currency)

    %{
      user_id: user_id,
      reporting_period: period,
      currency: currency,

      # Current Financial Position
      current_net_worth: position_report.net_worth,
      total_assets: position_report.total_assets,
      total_debt: position_report.total_debt,
      debt_to_asset_ratio: position_report.debt_to_asset_ratio,

      # Cash Flow Integration
      monthly_income: cash_flow_report.total_income,
      monthly_expenses: cash_flow_report.total_expenses,
      net_monthly_cash_flow: cash_flow_report.net_cash_flow,
      savings_rate: cash_flow_report.savings_rate,

      # Projected Net Worth
      projected_net_worth: net_worth_projection.projected_net_worth,
      net_worth_change: net_worth_projection.net_worth_change,
      projection_months: net_worth_projection.projection_months,

      # Financial Health Metrics
      risk_score: health_report.risk_score,
      financial_stability_score: health_report.financial_stability_score,
      liquidity_ratio: health_report.liquidity_ratio,
      emergency_fund_adequacy: health_report.emergency_fund_adequacy,

      # Cash Flow Impact
      annual_cash_flow_impact: cash_flow_impact.annual_impact,
      cash_flow_stability: cash_flow_impact.cash_flow_stability,
      income_diversity: cash_flow_impact.income_diversity,

      # Financial Ratios
      current_ratio: financial_ratios.current_ratio,
      quick_ratio: financial_ratios.quick_ratio,
      debt_to_income_ratio: financial_ratios.debt_to_income_ratio,
      debt_service_coverage_ratio: financial_ratios.debt_service_coverage_ratio,
      emergency_fund_ratio: financial_ratios.emergency_fund_ratio,
      investment_to_income_ratio: financial_ratios.investment_to_income_ratio,

      # Recommendations
      recommendations: health_report.recommendations,

      # Detailed Breakdowns
      assets_by_type: position_report.assets_by_type,
      debts_by_type: position_report.debts_by_type,
      income_by_category: cash_flow_report.income_by_category,
      expenses_by_category: cash_flow_report.expenses_by_category,
      recurring_income: cash_flow_report.recurring_income,
      recurring_expenses: cash_flow_report.recurring_expenses
    }
  end

  @doc """
  Tracks net worth changes over time for trend analysis.
  """
  def track_net_worth_history(user_id, start_period, end_period, currency \\ "USD") do
    periods = generate_period_range(start_period, end_period)

    history = Enum.map(periods, fn period ->
      report = generate_comprehensive_net_worth_report(user_id, period, currency)

      %{
        period: period,
        net_worth: report.current_net_worth,
        total_assets: report.total_assets,
        total_debt: report.total_debt,
        net_monthly_cash_flow: report.net_monthly_cash_flow,
        savings_rate: report.savings_rate,
        risk_score: report.risk_score,
        financial_stability_score: report.financial_stability_score
      }
    end)

    %{
      user_id: user_id,
      start_period: start_period,
      end_period: end_period,
      currency: currency,
      history: history,
      trend_analysis: analyze_net_worth_trend(history)
    }
  end

  @doc """
  Calculates net worth velocity (rate of change) and acceleration.
  """
  def calculate_net_worth_velocity(user_id, period, currency \\ "USD") do
    # Get current and previous period data
    current_report = generate_comprehensive_net_worth_report(user_id, period, currency)
    previous_period = get_previous_period(period)
    previous_report = generate_comprehensive_net_worth_report(user_id, previous_period, currency)

    current_net_worth = current_report.current_net_worth
    previous_net_worth = previous_report.current_net_worth

    net_worth_change = Decimal.sub(current_net_worth, previous_net_worth)
    net_worth_velocity = Decimal.div(net_worth_change, Decimal.new("1")) # Monthly velocity

    # Calculate acceleration (change in velocity)
    previous_velocity = calculate_previous_velocity(user_id, previous_period, currency)
    acceleration = Decimal.sub(net_worth_velocity, previous_velocity)

    %{
      user_id: user_id,
      period: period,
      currency: currency,
      current_net_worth: current_net_worth,
      previous_net_worth: previous_net_worth,
      net_worth_change: net_worth_change,
      net_worth_velocity: net_worth_velocity,
      acceleration: acceleration,
      velocity_trend: determine_velocity_trend(net_worth_velocity, acceleration)
    }
  end

  @doc """
  Validates all financial instruments for XBRL compliance.
  """
  def validate_all_xbrl_compliance do
    assets = list_assets()
    debts = list_debt_obligations()

    asset_validation = Enum.map(assets, &validate_asset_xbrl_compliance/1)
    debt_validation = Enum.map(debts, &validate_debt_xbrl_compliance/1)

    %{
      assets: asset_validation,
      debts: debt_validation,
      summary: %{
        total_assets: length(assets),
        total_debts: length(debts),
        valid_assets: Enum.count(asset_validation, & &1.valid),
        valid_debts: Enum.count(debt_validation, & &1.valid)
      }
    }
  end

  # Private functions

  defp validate_cash_flow_xbrl_rules(changeset) do
    cash_flow = Ecto.Changeset.apply_changes(changeset)
    {valid, errors} = CashFlow.validate_cash_flow_rules(cash_flow)
    if valid do
      changeset
    else
      Enum.reduce(errors, changeset, fn {field, message}, acc ->
        Ecto.Changeset.add_error(acc, field, message)
      end)
    end
  end

  defp get_assets_by_user_and_period(user_id, period) do
    Asset
    |> where([a], a.user_id == ^user_id and a.reporting_period == ^period and a.is_active == true)
    |> Repo.all()
  end

  defp get_debts_by_user_and_period(user_id, period) do
    DebtObligation
    |> where([d], d.user_id == ^user_id and d.reporting_period == ^period and d.is_active == true)
    |> Repo.all()
  end

  defp calculate_debt_to_asset_ratio(total_debt, total_assets) do
    if Decimal.eq?(total_assets, Decimal.new("0")) do
      Decimal.new("0")
    else
      Decimal.div(total_debt, total_assets)
    end
  end

  defp group_assets_by_type(assets) do
    assets
    |> Enum.group_by(& &1.asset_type)
    |> Enum.map(fn {type, type_assets} ->
      total_value = Enum.reduce(type_assets, Decimal.new("0"), fn asset, acc ->
        Decimal.add(acc, asset.fair_value)
      end)
      {type, total_value}
    end)
    |> Enum.sort_by(fn {_type, value} -> value end, :desc)
  end

  defp group_debts_by_type(debts) do
    debts
    |> Enum.group_by(& &1.debt_type)
    |> Enum.map(fn {type, type_debts} ->
      total_value = Enum.reduce(type_debts, Decimal.new("0"), fn debt, acc ->
        Decimal.add(acc, debt.outstanding_balance)
      end)
      {type, total_value}
    end)
    |> Enum.sort_by(fn {_type, value} -> value end, :desc)
  end

  defp validate_asset_xbrl_compliance(asset) do
    {valid, errors} = Asset.validate_xbrl_rules(asset)
    %{
      asset_id: asset.id,
      asset_identifier: asset.asset_identifier,
      valid: valid,
      errors: errors
    }
  end

  defp validate_debt_xbrl_compliance(debt) do
    {valid, errors} = DebtObligation.validate_xbrl_rules(debt)
    %{
      debt_id: debt.id,
      debt_identifier: debt.debt_identifier,
      valid: valid,
      errors: errors
    }
  end

  defp calculate_savings_rate(total_income, total_expenses) do
    if Decimal.eq?(total_income, Decimal.new("0")) do
      Decimal.new("0")
    else
      net_savings = Decimal.sub(total_income, total_expenses)
      Decimal.mult(Decimal.div(net_savings, total_income), Decimal.new("100"))
    end
  end

  defp filter_recurring_cash_flows(cash_flows, type) do
    cash_flows
    |> Enum.filter(&(&1.cash_flow_type == type && &1.is_recurring))
    |> Enum.sort_by(& &1.next_occurrence_date)
  end

  # Net worth tracking helper functions

  defp generate_period_range(start_period, end_period) do
    # Simple implementation - assumes YYYY-MM format
    # In a real implementation, you'd want more sophisticated period handling
    [start_period, end_period]
  end

  defp analyze_net_worth_trend(history) do
    if length(history) < 2 do
      %{trend: "insufficient_data", direction: "unknown", growth_rate: Decimal.new("0")}
    else
      [first | _] = history
      [last | _] = Enum.reverse(history)

      net_worth_change = Decimal.sub(last.net_worth, first.net_worth)
      growth_rate = if Decimal.eq?(first.net_worth, Decimal.new("0")) do
        Decimal.new("0")
      else
        Decimal.mult(Decimal.div(net_worth_change, first.net_worth), Decimal.new("100"))
      end

      direction = cond do
        Decimal.gt?(net_worth_change, Decimal.new("0")) -> "increasing"
        Decimal.lt?(net_worth_change, Decimal.new("0")) -> "decreasing"
        true -> "stable"
      end

      %{
        trend: "calculated",
        direction: direction,
        growth_rate: growth_rate,
        net_worth_change: net_worth_change,
        periods_analyzed: length(history)
      }
    end
  end

  defp get_previous_period(period) do
    # Simple implementation - assumes YYYY-MM format
    # In a real implementation, you'd want more sophisticated period handling
    case period do
      "2025-01" -> "2024-12"
      "2025-02" -> "2025-01"
      "2025-03" -> "2025-02"
      _ -> "2025-01" # Default fallback
    end
  end

  defp calculate_previous_velocity(_user_id, _previous_period, _currency) do
    # For simplicity, return 0 as previous velocity
    # In a real implementation, you'd calculate this from historical data
    Decimal.new("0")
  end

  defp determine_velocity_trend(net_worth_velocity, acceleration) do
    cond do
      Decimal.gt?(net_worth_velocity, Decimal.new("0")) and Decimal.gt?(acceleration, Decimal.new("0")) ->
        "accelerating_growth"
      Decimal.gt?(net_worth_velocity, Decimal.new("0")) and Decimal.lt?(acceleration, Decimal.new("0")) ->
        "decelerating_growth"
      Decimal.lt?(net_worth_velocity, Decimal.new("0")) and Decimal.gt?(acceleration, Decimal.new("0")) ->
        "recovering"
      Decimal.lt?(net_worth_velocity, Decimal.new("0")) and Decimal.lt?(acceleration, Decimal.new("0")) ->
        "accelerating_decline"
      true ->
        "stable"
    end
  end
end
