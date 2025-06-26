defmodule SoupAndNutz.FinancialAnalysis do
  @moduledoc """
  Provides comprehensive financial analysis by integrating assets, liabilities, and cash flows.
  This module calculates net worth, financial health metrics, and provides insights for financial planning.
  """

  import Ecto.Query, warn: false
  alias SoupAndNutz.Repo
  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.FinancialInstruments.{Asset, DebtObligation, CashFlow}

  @doc """
  Calculates comprehensive net worth including cash flow projections.
  """
  def calculate_net_worth(entity, period, currency \\ "USD", projection_months \\ 12) do
    assets = FinancialInstruments.list_assets_by_entity(entity)
    debts = FinancialInstruments.list_debt_obligations_by_entity(entity)
    cash_flows = FinancialInstruments.list_cash_flows_by_entity_and_period(entity, period)

    total_assets = Asset.total_fair_value(assets, currency)
    total_debts = DebtObligation.total_outstanding_debt(debts, currency)
    current_net_worth = Decimal.sub(total_assets, total_debts)

    # Calculate projected net worth based on cash flows
    projected_net_worth = calculate_projected_net_worth(
      current_net_worth,
      cash_flows,
      projection_months,
      currency
    )

    %{
      entity: entity,
      reporting_period: period,
      currency: currency,
      current_net_worth: current_net_worth,
      projected_net_worth: projected_net_worth,
      net_worth_change: Decimal.sub(projected_net_worth, current_net_worth),
      total_assets: total_assets,
      total_debts: total_debts,
      projection_months: projection_months
    }
  end

  @doc """
  Generates a comprehensive financial health report.
  """
  def generate_financial_health_report(entity, period, currency \\ "USD") do
    assets = FinancialInstruments.list_assets_by_entity(entity)
    debts = FinancialInstruments.list_debt_obligations_by_entity(entity)
    cash_flows = FinancialInstruments.list_cash_flows_by_entity_and_period(entity, period)

    total_assets = Asset.total_fair_value(assets, currency)
    total_debts = DebtObligation.total_outstanding_debt(debts, currency)
    net_worth = Decimal.sub(total_assets, total_debts)

    total_income = CashFlow.total_income(cash_flows, period, entity, currency)
    total_expenses = CashFlow.total_expenses(cash_flows, period, entity, currency)
    net_cash_flow = CashFlow.net_cash_flow(cash_flows, period, entity, currency)

    monthly_debt_payments = DebtObligation.total_monthly_payments(debts, currency)

    %{
      entity: entity,
      reporting_period: period,
      currency: currency,

      # Net Worth Analysis
      net_worth: net_worth,
      total_assets: total_assets,
      total_debts: total_debts,
      debt_to_asset_ratio: calculate_debt_to_asset_ratio(total_debts, total_assets),

      # Cash Flow Analysis
      monthly_income: total_income,
      monthly_expenses: total_expenses,
      net_monthly_cash_flow: net_cash_flow,
      savings_rate: calculate_savings_rate(total_income, total_expenses),

      # Debt Analysis
      monthly_debt_payments: monthly_debt_payments,
      debt_service_ratio: calculate_debt_service_ratio(monthly_debt_payments, total_income),

      # Financial Health Metrics
      liquidity_ratio: calculate_liquidity_ratio(assets, total_expenses),
      emergency_fund_adequacy: calculate_emergency_fund_adequacy(assets, total_expenses),
      investment_ratio: calculate_investment_ratio(assets, total_assets),

      # Risk Assessment
      risk_score: calculate_risk_score(assets, debts, cash_flows),
      financial_stability_score: calculate_financial_stability_score(net_worth, net_cash_flow, total_debts),

      # Recommendations
      recommendations: generate_recommendations(assets, debts, cash_flows, net_worth, net_cash_flow)
    }
  end

  @doc """
  Calculates projected net worth based on current cash flows.
  """
  def calculate_projected_net_worth(current_net_worth, cash_flows, months, currency) do
    monthly_net_cash_flow = calculate_monthly_net_cash_flow(cash_flows, currency)

    # Simple linear projection (could be enhanced with compound interest, market returns, etc.)
    projected_cash_flow_contribution = Decimal.mult(monthly_net_cash_flow, Decimal.new(months))
    Decimal.add(current_net_worth, projected_cash_flow_contribution)
  end

  @doc """
  Analyzes cash flow impact on net worth over time.
  """
  def analyze_cash_flow_impact(entity, period, currency \\ "USD", months \\ 12) do
    cash_flows = FinancialInstruments.list_cash_flows_by_entity_and_period(entity, period)

    monthly_income = CashFlow.total_income(cash_flows, period, entity, currency)
    monthly_expenses = CashFlow.total_expenses(cash_flows, period, entity, currency)
    monthly_net = Decimal.sub(monthly_income, monthly_expenses)

    # Calculate cumulative impact
    cumulative_impact = Enum.reduce(1..months, Decimal.new("0"), fn month, acc ->
      monthly_contribution = Decimal.mult(monthly_net, Decimal.new(month))
      Decimal.add(acc, monthly_contribution)
    end)

    %{
      entity: entity,
      period: period,
      currency: currency,
      analysis_months: months,
      monthly_income: monthly_income,
      monthly_expenses: monthly_expenses,
      monthly_net_cash_flow: monthly_net,
      cumulative_impact: cumulative_impact,
      annual_impact: Decimal.mult(monthly_net, Decimal.new("12")),
      cash_flow_stability: calculate_cash_flow_stability(cash_flows),
      income_diversity: calculate_income_diversity(cash_flows),
      expense_breakdown: CashFlow.group_by_category(cash_flows, "Expense")
    }
  end

  @doc """
  Calculates financial ratios and metrics for comprehensive analysis.
  """
  def calculate_financial_ratios(entity, period, currency \\ "USD") do
    assets = FinancialInstruments.list_assets_by_entity(entity)
    debts = FinancialInstruments.list_debt_obligations_by_entity(entity)
    cash_flows = FinancialInstruments.list_cash_flows_by_entity_and_period(entity, period)

    _total_assets = Asset.total_fair_value(assets, currency)
    total_debts = DebtObligation.total_outstanding_debt(debts, currency)
    monthly_income = CashFlow.total_income(cash_flows, period, entity, currency)
    monthly_expenses = CashFlow.total_expenses(cash_flows, period, entity, currency)
    monthly_debt_payments = DebtObligation.total_monthly_payments(debts, currency)

    %{
      entity: entity,
      period: period,
      currency: currency,

      # Liquidity Ratios
      current_ratio: calculate_current_ratio(assets, total_debts),
      quick_ratio: calculate_quick_ratio(assets, total_debts),

      # Debt Ratios
      debt_to_income_ratio: calculate_debt_to_income_ratio(total_debts, monthly_income),
      debt_service_coverage_ratio: calculate_debt_service_coverage_ratio(monthly_income, monthly_debt_payments),

      # Savings Ratios
      savings_rate: calculate_savings_rate(monthly_income, monthly_expenses),
      emergency_fund_ratio: calculate_emergency_fund_ratio(assets, monthly_expenses),

      # Investment Ratios
      investment_to_income_ratio: calculate_investment_to_income_ratio(assets, monthly_income),
      retirement_savings_ratio: calculate_retirement_savings_ratio(assets, monthly_income)
    }
  end

  # Private helper functions

  defp calculate_monthly_net_cash_flow(cash_flows, currency) do
    income_flows = Enum.filter(cash_flows, &(&1.cash_flow_type == "Income" && &1.currency_code == currency))
    expense_flows = Enum.filter(cash_flows, &(&1.cash_flow_type == "Expense" && &1.currency_code == currency))

    total_income = Enum.reduce(income_flows, Decimal.new("0"), fn cf, acc ->
      Decimal.add(acc, cf.amount)
    end)

    total_expenses = Enum.reduce(expense_flows, Decimal.new("0"), fn cf, acc ->
      Decimal.add(acc, cf.amount)
    end)

    Decimal.sub(total_income, total_expenses)
  end

  defp calculate_debt_to_asset_ratio(total_debt, total_assets) do
    if Decimal.eq?(total_assets, Decimal.new("0")) do
      Decimal.new("0")
    else
      Decimal.div(total_debt, total_assets)
    end
  end

  defp calculate_savings_rate(total_income, total_expenses) do
    if Decimal.eq?(total_income, Decimal.new("0")) do
      Decimal.new("0")
    else
      net_savings = Decimal.sub(total_income, total_expenses)
      Decimal.mult(Decimal.div(net_savings, total_income), Decimal.new("100"))
    end
  end

  defp calculate_debt_service_ratio(monthly_debt_payments, monthly_income) do
    if Decimal.eq?(monthly_income, Decimal.new("0")) do
      Decimal.new("0")
    else
      Decimal.mult(Decimal.div(monthly_debt_payments, monthly_income), Decimal.new("100"))
    end
  end

  defp calculate_liquidity_ratio(assets, monthly_expenses) do
    liquid_assets = Enum.filter(assets, &(&1.liquidity_level == "High"))
    liquid_value = Enum.reduce(liquid_assets, Decimal.new("0"), fn asset, acc ->
      Decimal.add(acc, asset.fair_value)
    end)

    if Decimal.eq?(monthly_expenses, Decimal.new("0")) do
      Decimal.new("0")
    else
      Decimal.div(liquid_value, monthly_expenses)
    end
  end

  defp calculate_emergency_fund_adequacy(assets, monthly_expenses) do
    emergency_funds = Enum.filter(assets, &(&1.asset_category == "Savings"))
    emergency_value = Enum.reduce(emergency_funds, Decimal.new("0"), fn asset, acc ->
      Decimal.add(acc, asset.fair_value)
    end)

    if Decimal.eq?(monthly_expenses, Decimal.new("0")) do
      Decimal.new("0")
    else
      Decimal.div(emergency_value, monthly_expenses)
    end
  end

  defp calculate_investment_ratio(assets, total_assets) do
    investment_assets = Enum.filter(assets, &(&1.asset_type == "InvestmentSecurities"))
    investment_value = Enum.reduce(investment_assets, Decimal.new("0"), fn asset, acc ->
      Decimal.add(acc, asset.fair_value)
    end)

    if Decimal.eq?(total_assets, Decimal.new("0")) do
      Decimal.new("0")
    else
      Decimal.mult(Decimal.div(investment_value, total_assets), Decimal.new("100"))
    end
  end

  defp calculate_risk_score(assets, debts, cash_flows) do
    # Simple risk scoring algorithm (1-10, where 10 is highest risk)
    risk_factors = [
      calculate_debt_risk(debts),
      calculate_liquidity_risk(assets),
      calculate_cash_flow_risk(cash_flows),
      calculate_concentration_risk(assets)
    ]

    average_risk = Enum.sum(risk_factors) / length(risk_factors)
    min(max(average_risk, 1), 10)
  end

  defp calculate_financial_stability_score(net_worth, net_cash_flow, total_debts) do
    # Financial stability score (1-10, where 10 is most stable)
    factors = [
      if Decimal.gt?(net_worth, Decimal.new("0")) do 2 else 0 end,
      if Decimal.gt?(net_cash_flow, Decimal.new("0")) do 2 else 0 end,
      if Decimal.lt?(total_debts, Decimal.new("100000")) do 2 else 0 end,
      if Decimal.gt?(net_cash_flow, Decimal.new("1000")) do 2 else 0 end,
      if Decimal.gt?(net_worth, Decimal.new("100000")) do 2 else 0 end
    ]

    min(Enum.sum(factors), 10)
  end

  defp calculate_debt_risk(debts) do
    total_debt = DebtObligation.total_outstanding_debt(debts, "USD")
    cond do
      Decimal.gt?(total_debt, Decimal.new("500000")) -> 8
      Decimal.gt?(total_debt, Decimal.new("200000")) -> 6
      Decimal.gt?(total_debt, Decimal.new("50000")) -> 4
      true -> 2
    end
  end

  defp calculate_liquidity_risk(assets) do
    liquid_assets = Enum.filter(assets, &(&1.liquidity_level == "High"))
    liquid_value = Enum.reduce(liquid_assets, Decimal.new("0"), fn asset, acc ->
      Decimal.add(acc, asset.fair_value)
    end)

    cond do
      Decimal.lt?(liquid_value, Decimal.new("5000")) -> 8
      Decimal.lt?(liquid_value, Decimal.new("10000")) -> 6
      Decimal.lt?(liquid_value, Decimal.new("25000")) -> 4
      true -> 2
    end
  end

  defp calculate_cash_flow_risk(cash_flows) do
    income_flows = Enum.filter(cash_flows, &(&1.cash_flow_type == "Income"))
    expense_flows = Enum.filter(cash_flows, &(&1.cash_flow_type == "Expense"))

    total_income = Enum.reduce(income_flows, Decimal.new("0"), fn cf, acc ->
      Decimal.add(acc, cf.amount)
    end)

    total_expenses = Enum.reduce(expense_flows, Decimal.new("0"), fn cf, acc ->
      Decimal.add(acc, cf.amount)
    end)

    net_cash_flow = Decimal.sub(total_income, total_expenses)

    cond do
      Decimal.lt?(net_cash_flow, Decimal.new("0")) -> 8
      Decimal.lt?(net_cash_flow, Decimal.new("500")) -> 6
      Decimal.lt?(net_cash_flow, Decimal.new("1000")) -> 4
      true -> 2
    end
  end

  defp calculate_concentration_risk(assets) do
    total_value = Asset.total_fair_value(assets, "USD")

    if Decimal.eq?(total_value, Decimal.new("0")) do
      5
    else
      # Check if any single asset represents more than 50% of total assets
      max_concentration = Enum.reduce(assets, Decimal.new("0"), fn asset, max_so_far ->
        concentration = Decimal.div(asset.fair_value, total_value)
        if Decimal.gt?(concentration, max_so_far), do: concentration, else: max_so_far
      end)

      cond do
        Decimal.gt?(max_concentration, Decimal.new("0.7")) -> 8
        Decimal.gt?(max_concentration, Decimal.new("0.5")) -> 6
        Decimal.gt?(max_concentration, Decimal.new("0.3")) -> 4
        true -> 2
      end
    end
  end

  defp calculate_cash_flow_stability(cash_flows) do
    recurring_income = Enum.filter(cash_flows, &(&1.cash_flow_type == "Income" && &1.is_recurring))
    total_income = CashFlow.total_income(cash_flows, "2025-01", "SMITH_FAMILY_001", "USD")

    if Decimal.eq?(total_income, Decimal.new("0")) do
      Decimal.new("0")
    else
      recurring_income_total = Enum.reduce(recurring_income, Decimal.new("0"), fn cf, acc ->
        Decimal.add(acc, cf.amount)
      end)
      Decimal.mult(Decimal.div(recurring_income_total, total_income), Decimal.new("100"))
    end
  end

  defp calculate_income_diversity(cash_flows) do
    income_flows = Enum.filter(cash_flows, &(&1.cash_flow_type == "Income"))
    unique_categories = income_flows |> Enum.map(& &1.cash_flow_category) |> Enum.uniq()
    length(unique_categories)
  end

  defp calculate_current_ratio(assets, total_debts) do
    if Decimal.eq?(total_debts, Decimal.new("0")) do
      Decimal.new("0")
    else
      total_assets = Asset.total_fair_value(assets, "USD")
      Decimal.div(total_assets, total_debts)
    end
  end

  defp calculate_quick_ratio(assets, total_debts) do
    if Decimal.eq?(total_debts, Decimal.new("0")) do
      Decimal.new("0")
    else
      liquid_assets = Enum.filter(assets, &(&1.liquidity_level == "High"))
      liquid_value = Enum.reduce(liquid_assets, Decimal.new("0"), fn asset, acc ->
        Decimal.add(acc, asset.fair_value)
      end)
      Decimal.div(liquid_value, total_debts)
    end
  end

  defp calculate_debt_to_income_ratio(total_debts, monthly_income) do
    if Decimal.eq?(monthly_income, Decimal.new("0")) do
      Decimal.new("0")
    else
      annual_income = Decimal.mult(monthly_income, Decimal.new("12"))
      Decimal.mult(Decimal.div(total_debts, annual_income), Decimal.new("100"))
    end
  end

  defp calculate_debt_service_coverage_ratio(monthly_income, monthly_debt_payments) do
    if Decimal.eq?(monthly_debt_payments, Decimal.new("0")) do
      Decimal.new("0")
    else
      Decimal.div(monthly_income, monthly_debt_payments)
    end
  end

  defp calculate_emergency_fund_ratio(assets, monthly_expenses) do
    if Decimal.eq?(monthly_expenses, Decimal.new("0")) do
      Decimal.new("0")
    else
      emergency_funds = Enum.filter(assets, &(&1.asset_category == "Savings"))
      emergency_value = Enum.reduce(emergency_funds, Decimal.new("0"), fn asset, acc ->
        Decimal.add(acc, asset.fair_value)
      end)
      Decimal.div(emergency_value, monthly_expenses)
    end
  end

  defp calculate_investment_to_income_ratio(assets, monthly_income) do
    if Decimal.eq?(monthly_income, Decimal.new("0")) do
      Decimal.new("0")
    else
      investment_assets = Enum.filter(assets, &(&1.asset_type == "InvestmentSecurities"))
      investment_value = Enum.reduce(investment_assets, Decimal.new("0"), fn asset, acc ->
        Decimal.add(acc, asset.fair_value)
      end)
      annual_income = Decimal.mult(monthly_income, Decimal.new("12"))
      Decimal.mult(Decimal.div(investment_value, annual_income), Decimal.new("100"))
    end
  end

  defp calculate_retirement_savings_ratio(assets, monthly_income) do
    if Decimal.eq?(monthly_income, Decimal.new("0")) do
      Decimal.new("0")
    else
      retirement_assets = Enum.filter(assets, &(&1.asset_category == "Retirement"))
      retirement_value = Enum.reduce(retirement_assets, Decimal.new("0"), fn asset, acc ->
        Decimal.add(acc, asset.fair_value)
      end)
      annual_income = Decimal.mult(monthly_income, Decimal.new("12"))
      Decimal.mult(Decimal.div(retirement_value, annual_income), Decimal.new("100"))
    end
  end

  defp generate_recommendations(assets, _debts, _cash_flows, net_worth, net_cash_flow) do
    recommendations = []

    # Net worth recommendations
    if Decimal.lt?(net_worth, Decimal.new("0")) do
      recommendations = [%{
        category: "Net Worth",
        priority: "High",
        title: "Negative Net Worth",
        description: "Focus on debt reduction and increasing income to achieve positive net worth",
        action_items: ["Increase income", "Reduce expenses", "Pay down high-interest debt"]
      } | recommendations]
    end

    # Cash flow recommendations
    if Decimal.lt?(net_cash_flow, Decimal.new("0")) do
      recommendations = [%{
        category: "Cash Flow",
        priority: "Critical",
        title: "Negative Cash Flow",
        description: "Monthly expenses exceed income - immediate action required",
        action_items: ["Reduce discretionary spending", "Increase income", "Review all expenses"]
      } | recommendations]
    end

    # Emergency fund recommendations
    emergency_funds = Enum.filter(assets, &(&1.asset_category == "Savings"))
    emergency_value = Enum.reduce(emergency_funds, Decimal.new("0"), fn asset, acc ->
      Decimal.add(acc, asset.fair_value)
    end)

    if Decimal.lt?(emergency_value, Decimal.new("10000")) do
      recommendations = [%{
        category: "Emergency Fund",
        priority: "High",
        title: "Insufficient Emergency Fund",
        description: "Emergency fund should cover 3-6 months of expenses",
        action_items: ["Set up automatic savings", "Reduce expenses", "Allocate windfalls to emergency fund"]
      } | recommendations]
    end

    # Investment recommendations
    investment_assets = Enum.filter(assets, &(&1.asset_type == "InvestmentSecurities"))
    investment_value = Enum.reduce(investment_assets, Decimal.new("0"), fn asset, acc ->
      Decimal.add(acc, asset.fair_value)
    end)

    if Decimal.lt?(investment_value, Decimal.new("50000")) do
      recommendations = [%{
        category: "Investments",
        priority: "Medium",
        title: "Increase Investment Allocation",
        description: "Consider increasing investment contributions for long-term wealth building",
        action_items: ["Increase 401(k) contributions", "Start IRA contributions", "Consider taxable investments"]
      } | recommendations]
    end

    recommendations
  end
end
