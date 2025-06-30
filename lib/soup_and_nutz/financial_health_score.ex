defmodule SoupAndNutz.FinancialHealthScore do
  @moduledoc """
  Calculates financial health scores and metrics for users based on their financial data.

  This module analyzes assets, debts, cash flows, and other financial instruments
  to provide a comprehensive view of financial health and actionable recommendations.
  """

  alias SoupAndNutz.FinancialInstruments.{Asset, DebtObligation, CashFlow}
  alias Decimal, as: D

  @doc """
  Calculates a comprehensive financial health score for a user.

  Returns a map containing:
  - overall_score: 0-100 overall financial health score
  - metrics: Individual metric scores and details
  - recommendations: Actionable improvement suggestions
  """
  def calculate_health_score(user_id, currency \\ "USD") do
    # Get user's financial data
    assets = get_user_assets(user_id, currency)
    debts = get_user_debts(user_id, currency)
    cash_flows = get_user_cash_flows(user_id, currency)

    # Calculate individual metrics
    savings_rate = calculate_savings_rate(cash_flows, currency)
    debt_to_income = calculate_debt_to_income_ratio(debts, cash_flows, currency)
    emergency_fund = calculate_emergency_fund_adequacy(assets, cash_flows, currency)
    investment_diversification = calculate_investment_diversification(assets, currency)
    net_worth_trend = calculate_net_worth_trend(assets, debts, currency)

    # Calculate overall score (weighted average)
    overall_score = calculate_overall_score([
      {savings_rate.score, 25},      # 25% weight
      {debt_to_income.score, 25},    # 25% weight
      {emergency_fund.score, 20},    # 20% weight
      {investment_diversification.score, 15}, # 15% weight
      {net_worth_trend.score, 15}    # 15% weight
    ])

    # Generate recommendations
    recommendations = generate_recommendations(%{
      savings_rate: savings_rate,
      debt_to_income: debt_to_income,
      emergency_fund: emergency_fund,
      investment_diversification: investment_diversification,
      net_worth_trend: net_worth_trend
    })

    %{
      overall_score: overall_score,
      metrics: %{
        savings_rate: savings_rate,
        debt_to_income: debt_to_income,
        emergency_fund: emergency_fund,
        investment_diversification: investment_diversification,
        net_worth_trend: net_worth_trend
      },
      recommendations: recommendations,
      calculated_at: DateTime.utc_now()
    }
  end

  @doc """
  Calculates savings rate as a percentage of income.
  """
  def calculate_savings_rate(cash_flows, currency) do
    # Get monthly income and expenses
    monthly_income = CashFlow.total_income(cash_flows, get_current_period(), currency)
    monthly_expenses = CashFlow.total_expenses(cash_flows, get_current_period(), currency)
    monthly_savings = D.sub(monthly_income, monthly_expenses)

    savings_rate_percentage = if D.gt?(monthly_income, D.new(0)) do
      D.mult(D.div(monthly_savings, monthly_income), D.new(100))
    else
      D.new(0)
    end

    # Score based on savings rate (0-100)
    score = cond do
      D.gte?(savings_rate_percentage, D.new(20)) -> 100  # 20%+ is excellent
      D.gte?(savings_rate_percentage, D.new(15)) -> 85   # 15-20% is very good
      D.gte?(savings_rate_percentage, D.new(10)) -> 70   # 10-15% is good
      D.gte?(savings_rate_percentage, D.new(5)) -> 50    # 5-10% is fair
      D.gte?(savings_rate_percentage, D.new(0)) -> 25    # 0-5% is poor
      true -> 0                                          # Negative savings
    end

    %{
      score: score,
      percentage: savings_rate_percentage,
      monthly_income: monthly_income,
      monthly_expenses: monthly_expenses,
      monthly_savings: monthly_savings,
      description: "Savings rate as percentage of income"
    }
  end

  @doc """
  Calculates debt-to-income ratio.
  """
  def calculate_debt_to_income_ratio(debts, cash_flows, currency) do
    monthly_debt_payments = DebtObligation.total_monthly_payments(debts, currency)
    monthly_income = CashFlow.total_income(cash_flows, get_current_period(), currency)

    debt_to_income_ratio = if D.gt?(monthly_income, D.new(0)) do
      D.mult(D.div(monthly_debt_payments, monthly_income), D.new(100))
    else
      D.new(0)
    end

    # Score based on debt-to-income ratio (0-100)
    score = cond do
      D.lte?(debt_to_income_ratio, D.new(20)) -> 100   # <20% is excellent
      D.lte?(debt_to_income_ratio, D.new(30)) -> 85    # 20-30% is very good
      D.lte?(debt_to_income_ratio, D.new(40)) -> 70    # 30-40% is good
      D.lte?(debt_to_income_ratio, D.new(50)) -> 50    # 40-50% is fair
      D.lte?(debt_to_income_ratio, D.new(60)) -> 25    # 50-60% is poor
      true -> 0                                        # >60% is very poor
    end

    %{
      score: score,
      ratio: debt_to_income_ratio,
      monthly_debt_payments: monthly_debt_payments,
      monthly_income: monthly_income,
      description: "Monthly debt payments as percentage of income"
    }
  end

  @doc """
  Calculates emergency fund adequacy (liquid assets vs monthly expenses).
  """
  def calculate_emergency_fund_adequacy(assets, cash_flows, currency) do
    # Get liquid assets (cash, checking, savings)
    liquid_assets = assets
    |> Enum.filter(&(&1.asset_type in ["Cash", "Checking", "Savings"] && &1.is_active))
    |> Asset.total_fair_value(currency)

    monthly_expenses = CashFlow.total_expenses(cash_flows, get_current_period(), currency)

    months_of_expenses = if D.gt?(monthly_expenses, D.new(0)) do
      D.div(liquid_assets, monthly_expenses)
    else
      D.new(0)
    end

    # Score based on months of expenses covered (0-100)
    score = cond do
      D.gte?(months_of_expenses, D.new(6)) -> 100   # 6+ months is excellent
      D.gte?(months_of_expenses, D.new(4)) -> 85    # 4-6 months is very good
      D.gte?(months_of_expenses, D.new(3)) -> 70    # 3-4 months is good
      D.gte?(months_of_expenses, D.new(2)) -> 50    # 2-3 months is fair
      D.gte?(months_of_expenses, D.new(1)) -> 25    # 1-2 months is poor
      true -> 0                                     # <1 month is very poor
    end

    %{
      score: score,
      months_of_expenses: months_of_expenses,
      liquid_assets: liquid_assets,
      monthly_expenses: monthly_expenses,
      description: "Emergency fund coverage in months of expenses"
    }
  end

  @doc """
  Calculates investment diversification score.
  """
  def calculate_investment_diversification(assets, currency) do
    # Get investment assets only
    investment_assets = assets
    |> Enum.filter(&(&1.asset_type in ["Investment", "Retirement", "RealEstate"] && &1.is_active))
    |> Enum.filter(&(&1.currency_code == currency))

    total_investment_value = Asset.total_fair_value(investment_assets, currency)

    if D.eq?(total_investment_value, D.new(0)) do
      %{
        score: 0,
        diversification_score: D.new(0),
        asset_categories: [],
        total_investment_value: total_investment_value,
        description: "No investment assets found"
      }
    else
      # Calculate diversification based on number of asset categories
      asset_categories = investment_assets
      |> Enum.map(& &1.asset_category)
      |> Enum.uniq()
      |> length()

      # Score based on number of asset categories (0-100)
      score = cond do
        asset_categories >= 5 -> 100   # 5+ categories is excellent
        asset_categories >= 4 -> 85    # 4 categories is very good
        asset_categories >= 3 -> 70    # 3 categories is good
        asset_categories >= 2 -> 50    # 2 categories is fair
        asset_categories >= 1 -> 25    # 1 category is poor
        true -> 0                     # No investments
      end

      %{
        score: score,
        diversification_score: D.new(asset_categories),
        asset_categories: asset_categories,
        total_investment_value: total_investment_value,
        description: "Investment diversification based on asset categories"
      }
    end
  end

  @doc """
  Calculates net worth trend (simplified - positive net worth gets good score).
  """
  def calculate_net_worth_trend(assets, debts, currency) do
    total_assets = Asset.total_fair_value(assets, currency)
    total_debts = DebtObligation.total_outstanding_debt(debts, currency)
    net_worth = D.sub(total_assets, total_debts)

    # Score based on net worth (0-100)
    score = cond do
      D.gt?(net_worth, D.new(0)) -> 100   # Positive net worth is excellent
      D.gte?(net_worth, D.new(-10000)) -> 70   # Small negative is manageable
      D.gte?(net_worth, D.new(-50000)) -> 50   # Moderate negative is concerning
      D.gte?(net_worth, D.new(-100000)) -> 25  # Large negative is poor
      true -> 0                              # Very large negative is very poor
    end

    %{
      score: score,
      net_worth: net_worth,
      total_assets: total_assets,
      total_debts: total_debts,
      description: "Current net worth position"
    }
  end

  @doc """
  Calculates overall weighted score from individual metrics.
  """
  def calculate_overall_score(metric_weights) do
    total_weight = metric_weights
    |> Enum.map(fn {_score, weight} -> weight end)
    |> Enum.sum()

    weighted_sum = metric_weights
    |> Enum.map(fn {score, weight} -> score * weight end)
    |> Enum.sum()

    round(weighted_sum / total_weight)
  end

  @doc """
  Generates actionable recommendations based on metric scores.
  """
  def generate_recommendations(metrics) do
    recommendations = []

    recommendations = if metrics.savings_rate.score < 70 do
      [
        "Increase your savings rate to at least 10-15% of your income",
        "Consider setting up automatic transfers to savings accounts",
        "Review your expenses to identify areas for reduction"
      ] ++ recommendations
    else
      recommendations
    end

    recommendations = if metrics.debt_to_income.score < 70 do
      [
        "Focus on paying down high-interest debt first",
        "Consider debt consolidation to lower interest rates",
        "Avoid taking on new debt until ratio improves"
      ] ++ recommendations
    else
      recommendations
    end

    recommendations = if metrics.emergency_fund.score < 70 do
      [
        "Build an emergency fund covering 3-6 months of expenses",
        "Set aside a portion of each paycheck for emergencies",
        "Consider high-yield savings accounts for emergency funds"
      ] ++ recommendations
    else
      recommendations
    end

    recommendations = if metrics.investment_diversification.score < 70 do
      [
        "Diversify your investments across different asset classes",
        "Consider index funds for broad market exposure",
        "Review your asset allocation regularly"
      ] ++ recommendations
    else
      recommendations
    end

    recommendations = if metrics.net_worth_trend.score < 70 do
      [
        "Focus on increasing assets while reducing debt",
        "Consider additional income sources",
        "Review your spending habits and budget"
      ] ++ recommendations
    else
      recommendations
    end

    # Add positive reinforcement for good scores
    good_metrics = Enum.filter(metrics, fn {_name, metric} -> metric.score >= 70 end)
    if length(good_metrics) >= 3 do
      [
        "Great job! You're on the right track with your finances",
        "Continue maintaining these good financial habits"
      ] ++ recommendations
    else
      recommendations
    end
  end

  # Helper functions

  defp get_user_assets(user_id, currency) do
    # This would typically query the database
    # For now, return empty list - implement based on your repo
    []
  end

  defp get_user_debts(user_id, currency) do
    # This would typically query the database
    # For now, return empty list - implement based on your repo
    []
  end

  defp get_user_cash_flows(user_id, currency) do
    # This would typically query the database
    # For now, return empty list - implement based on your repo
    []
  end

  defp get_current_period do
    # Return current month in format "YYYY-MM"
    Date.utc_today()
    |> Date.to_string()
    |> String.slice(0, 7)
  end
end
