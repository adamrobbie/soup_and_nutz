defmodule SoupAndNutz.BudgetPlanner do
  @moduledoc """
  Comprehensive budget planning and management system.

  This module provides budget creation, tracking, analysis, and optimization
  features that integrate with the existing cash flow and financial instruments.
  """

  import Ecto.Query, warn: false
  alias SoupAndNutz.{FinancialInstruments, Repo}
  alias SoupAndNutz.FinancialInstruments.CashFlow

  @doc """
  Creates a comprehensive budget based on historical cash flows and goals.
  """
  def create_budget(entity, period, budget_type \\ "50/30/20", goals \\ []) do
    # Get historical cash flows for analysis
    cash_flows = FinancialInstruments.list_cash_flows_by_entity_and_period(entity, period)

    income_flows = Enum.filter(cash_flows, &(&1.cash_flow_type == "Income"))
    expense_flows = Enum.filter(cash_flows, &(&1.cash_flow_type == "Expense"))

    total_income = calculate_total_amount(income_flows)
    historical_expenses = group_expenses_by_category(expense_flows)

    budget_allocation = case budget_type do
      "50/30/20" -> create_50_30_20_budget(total_income)
      "zero_based" -> create_zero_based_budget(total_income, historical_expenses)
      "envelope" -> create_envelope_budget(total_income, historical_expenses)
      "custom" -> create_custom_budget(total_income, goals)
    end

    %{
      entity: entity,
      period: period,
      budget_type: budget_type,
      total_income: total_income,
      budget_allocation: budget_allocation,
      historical_expenses: historical_expenses,
      savings_goal: Map.get(budget_allocation, "Savings", Decimal.new("0")),
      created_at: DateTime.utc_now(),
      goals: goals
    }
  end

  @doc """
  Analyzes budget vs actual spending performance.
  """
  def analyze_budget_performance(entity, period, budget) do
    actual_flows = FinancialInstruments.list_cash_flows_by_entity_and_period(entity, period)
    actual_expenses = group_expenses_by_category(actual_flows)

    performance_analysis = Enum.map(budget.budget_allocation, fn {category, budgeted_amount} ->
      actual_amount = Map.get(actual_expenses, category, Decimal.new("0"))
      variance = Decimal.sub(budgeted_amount, actual_amount)
      variance_percentage = calculate_variance_percentage(budgeted_amount, actual_amount)

      status = cond do
        Decimal.gt?(variance, Decimal.new("0")) -> "under_budget"
        Decimal.eq?(variance, Decimal.new("0")) -> "on_budget"
        true -> "over_budget"
      end

      %{
        category: category,
        budgeted: budgeted_amount,
        actual: actual_amount,
        variance: variance,
        variance_percentage: variance_percentage,
        status: status
      }
    end)

    %{
      entity: entity,
      period: period,
      overall_performance: calculate_overall_performance(performance_analysis),
      category_performance: performance_analysis,
      recommendations: generate_budget_recommendations(performance_analysis),
      savings_achieved: calculate_savings_achieved(budget, actual_expenses)
    }
  end

  @doc """
  Generates budget optimization recommendations.
  """
  def optimize_budget(entity, period, current_budget, financial_goals) do
    performance = analyze_budget_performance(entity, period, current_budget)

    optimization_suggestions = []

    # Analyze overspending categories
    overspent_categories = Enum.filter(performance.category_performance,
      &(&1.status == "over_budget"))

    optimization_suggestions = if length(overspent_categories) > 0 do
      overspending_suggestions = Enum.map(overspent_categories, fn category ->
        %{
          type: "reduce_spending",
          category: category.category,
          current_amount: category.actual,
          suggested_amount: category.budgeted,
          potential_savings: Decimal.abs(category.variance),
          priority: determine_reduction_priority(category)
        }
      end)
      optimization_suggestions ++ overspending_suggestions
    else
      optimization_suggestions
    end

    # Analyze underspending for reallocation
    underspent_categories = Enum.filter(performance.category_performance,
      &(&1.status == "under_budget"))

    optimization_suggestions = if length(underspent_categories) > 0 do
      reallocation_suggestions = suggest_reallocation(underspent_categories, financial_goals)
      optimization_suggestions ++ reallocation_suggestions
    else
      optimization_suggestions
    end

    %{
      entity: entity,
      period: period,
      current_performance: performance.overall_performance,
      optimization_suggestions: optimization_suggestions,
      projected_savings: calculate_projected_savings(optimization_suggestions),
      goal_impact: analyze_goal_impact(optimization_suggestions, financial_goals)
    }
  end

  @doc """
  Creates budget alerts and notifications.
  """
  def check_budget_alerts(entity, period, budget) do
    current_spending = get_current_month_spending(entity, period)

    alerts = Enum.reduce(budget.budget_allocation, [], fn {category, budgeted_amount}, acc ->
      actual_spent = Map.get(current_spending, category, Decimal.new("0"))
      percentage_used = if Decimal.gt?(budgeted_amount, Decimal.new("0")) do
        Decimal.mult(Decimal.div(actual_spent, budgeted_amount), Decimal.new("100"))
      else
        Decimal.new("0")
      end

      alert = cond do
        Decimal.gt?(percentage_used, Decimal.new("100")) ->
          %{type: "over_budget", category: category, severity: "high",
            message: "#{category} is over budget by #{format_percentage(Decimal.sub(percentage_used, Decimal.new("100")))}%"}

        Decimal.gt?(percentage_used, Decimal.new("90")) ->
          %{type: "approaching_limit", category: category, severity: "medium",
            message: "#{category} is at #{format_percentage(percentage_used)}% of budget"}

        Decimal.gt?(percentage_used, Decimal.new("75")) ->
          %{type: "warning", category: category, severity: "low",
            message: "#{category} is at #{format_percentage(percentage_used)}% of budget"}

        true -> nil
      end

      if alert, do: [alert | acc], else: acc
    end)

    %{
      entity: entity,
      period: period,
      alerts: alerts,
      alert_count: length(alerts),
      highest_severity: determine_highest_severity(alerts)
    }
  end

  # Private helper functions

  defp create_50_30_20_budget(total_income) do
    needs = Decimal.mult(total_income, Decimal.new("0.50"))
    wants = Decimal.mult(total_income, Decimal.new("0.30"))
    savings = Decimal.mult(total_income, Decimal.new("0.20"))

    %{
      "Housing" => Decimal.mult(needs, Decimal.new("0.60")),  # 30% of income
      "Food" => Decimal.mult(needs, Decimal.new("0.25")),     # 12.5% of income
      "Transportation" => Decimal.mult(needs, Decimal.new("0.15")), # 7.5% of income
      "Entertainment" => Decimal.mult(wants, Decimal.new("0.50")),  # 15% of income
      "Shopping" => Decimal.mult(wants, Decimal.new("0.50")),       # 15% of income
      "Savings" => savings,                                         # 20% of income
      "Emergency Fund" => Decimal.mult(savings, Decimal.new("0.50")), # 10% of income
      "Investments" => Decimal.mult(savings, Decimal.new("0.50"))     # 10% of income
    }
  end

  defp create_zero_based_budget(total_income, historical_expenses) do
    # Start with historical averages and adjust to total income
    base_budget = Enum.reduce(historical_expenses, %{}, fn {category, amount}, acc ->
      Map.put(acc, category, amount)
    end)

    total_historical = Enum.reduce(historical_expenses, Decimal.new("0"), fn {_, amount}, acc ->
      Decimal.add(acc, amount)
    end)

    # Scale to match income and ensure savings
    if Decimal.gt?(total_historical, total_income) do
      # Scale down proportionally
      scale_factor = Decimal.div(Decimal.mult(total_income, Decimal.new("0.90")), total_historical)
      scaled_budget = Enum.reduce(base_budget, %{}, fn {category, amount}, acc ->
        Map.put(acc, category, Decimal.mult(amount, scale_factor))
      end)
      Map.put(scaled_budget, "Savings", Decimal.mult(total_income, Decimal.new("0.10")))
    else
      # Add savings from surplus
      surplus = Decimal.sub(total_income, total_historical)
      Map.put(base_budget, "Savings", surplus)
    end
  end

  defp create_envelope_budget(total_income, historical_expenses) do
    # Similar to zero-based but with more granular category breakdown
    create_zero_based_budget(total_income, historical_expenses)
  end

  defp create_custom_budget(total_income, goals) do
    # Create budget based on specific financial goals
    base_budget = %{
      "Housing" => Decimal.mult(total_income, Decimal.new("0.25")),
      "Food" => Decimal.mult(total_income, Decimal.new("0.15")),
      "Transportation" => Decimal.mult(total_income, Decimal.new("0.10")),
      "Utilities" => Decimal.mult(total_income, Decimal.new("0.05"))
    }

    # Allocate remaining income based on goals
    allocated = Enum.reduce(base_budget, Decimal.new("0"), fn {_, amount}, acc ->
      Decimal.add(acc, amount)
    end)

    remaining = Decimal.sub(total_income, allocated)

    # Distribute remaining based on goals priority
    goal_allocations = distribute_by_goals(remaining, goals)

    Map.merge(base_budget, goal_allocations)
  end

  defp group_expenses_by_category(expense_flows) do
    expense_flows
    |> Enum.group_by(& &1.cash_flow_category)
    |> Enum.reduce(%{}, fn {category, flows}, acc ->
      total = calculate_total_amount(flows)
      Map.put(acc, category, total)
    end)
  end

  defp calculate_total_amount(flows) do
    Enum.reduce(flows, Decimal.new("0"), fn flow, acc ->
      Decimal.add(acc, flow.amount)
    end)
  end

  defp calculate_variance_percentage(budgeted, actual) do
    if Decimal.gt?(budgeted, Decimal.new("0")) do
      variance = Decimal.sub(budgeted, actual)
      Decimal.mult(Decimal.div(variance, budgeted), Decimal.new("100"))
    else
      Decimal.new("0")
    end
  end

  defp calculate_overall_performance(performance_analysis) do
    total_categories = length(performance_analysis)
    on_or_under_budget = Enum.count(performance_analysis, &(&1.status != "over_budget"))

    performance_score = if total_categories > 0 do
      Decimal.mult(Decimal.div(Decimal.new(on_or_under_budget), Decimal.new(total_categories)), Decimal.new("100"))
    else
      Decimal.new("0")
    end

    %{
      score: performance_score,
      total_categories: total_categories,
      on_budget_categories: on_or_under_budget,
      status: determine_overall_status(performance_score)
    }
  end

  defp determine_overall_status(score) do
    cond do
      Decimal.gte?(score, Decimal.new("90")) -> "excellent"
      Decimal.gte?(score, Decimal.new("75")) -> "good"
      Decimal.gte?(score, Decimal.new("60")) -> "fair"
      true -> "needs_improvement"
    end
  end

  defp generate_budget_recommendations(performance_analysis) do
    over_budget = Enum.filter(performance_analysis, &(&1.status == "over_budget"))
    under_budget = Enum.filter(performance_analysis, &(&1.status == "under_budget"))

    recommendations = []

    recommendations = if length(over_budget) > 0 do
      spending_recs = Enum.map(over_budget, fn category ->
        "Consider reducing spending in #{category.category} by #{format_currency(Decimal.abs(category.variance))}"
      end)
      recommendations ++ spending_recs
    else
      recommendations
    end

    recommendations = if length(under_budget) > 0 do
      surplus_recs = ["You have surplus in #{length(under_budget)} categories that could be reallocated to savings or debt payoff"]
      recommendations ++ surplus_recs
    else
      recommendations
    end

    recommendations
  end

  defp calculate_savings_achieved(budget, actual_expenses) do
    budgeted_savings = Map.get(budget.budget_allocation, "Savings", Decimal.new("0"))
    actual_total_expenses = Enum.reduce(actual_expenses, Decimal.new("0"), fn {_, amount}, acc ->
      Decimal.add(acc, amount)
    end)

    actual_savings = Decimal.sub(budget.total_income, actual_total_expenses)

    %{
      budgeted_savings: budgeted_savings,
      actual_savings: actual_savings,
      savings_variance: Decimal.sub(actual_savings, budgeted_savings)
    }
  end

  defp determine_reduction_priority(category) do
    # Determine priority based on category type and variance amount
    variance_amount = Decimal.abs(category.variance)

    cond do
      Decimal.gt?(variance_amount, Decimal.new("500")) -> "high"
      Decimal.gt?(variance_amount, Decimal.new("200")) -> "medium"
      true -> "low"
    end
  end

  defp suggest_reallocation(underspent_categories, financial_goals) do
    total_surplus = Enum.reduce(underspent_categories, Decimal.new("0"), fn category, acc ->
      Decimal.add(acc, category.variance)
    end)

    [
      %{
        type: "increase_savings",
        description: "Reallocate surplus to emergency fund",
        amount: Decimal.mult(total_surplus, Decimal.new("0.50")),
        priority: "high"
      },
      %{
        type: "debt_payoff",
        description: "Apply surplus to debt payoff",
        amount: Decimal.mult(total_surplus, Decimal.new("0.30")),
        priority: "medium"
      },
      %{
        type: "goal_funding",
        description: "Allocate to financial goals",
        amount: Decimal.mult(total_surplus, Decimal.new("0.20")),
        priority: "medium"
      }
    ]
  end

  defp calculate_projected_savings(optimization_suggestions) do
    Enum.reduce(optimization_suggestions, Decimal.new("0"), fn suggestion, acc ->
      case suggestion do
        %{potential_savings: savings} -> Decimal.add(acc, savings)
        %{amount: amount} -> Decimal.add(acc, amount)
        _ -> acc
      end
    end)
  end

  defp analyze_goal_impact(optimization_suggestions, financial_goals) do
    # Analyze how optimization suggestions impact financial goals
    %{
      accelerated_goals: [],
      goal_timeline_improvements: %{},
      recommended_goal_adjustments: []
    }
  end

  defp get_current_month_spending(entity, period) do
    # Get current month spending by category
    current_flows = FinancialInstruments.list_cash_flows_by_entity_and_period(entity, period)
    expense_flows = Enum.filter(current_flows, &(&1.cash_flow_type == "Expense"))
    group_expenses_by_category(expense_flows)
  end

  defp format_percentage(decimal) do
    decimal
    |> Decimal.round(1)
    |> Decimal.to_string()
  end

  defp format_currency(decimal) do
    "$" <> (decimal |> Decimal.round(2) |> Decimal.to_string())
  end

  defp determine_highest_severity(alerts) do
    cond do
      Enum.any?(alerts, &(&1.severity == "high")) -> "high"
      Enum.any?(alerts, &(&1.severity == "medium")) -> "medium"
      Enum.any?(alerts, &(&1.severity == "low")) -> "low"
      true -> "none"
    end
  end

  defp distribute_by_goals(remaining_amount, goals) do
    # Simple equal distribution for now - could be enhanced with priority weighting
    if length(goals) > 0 do
      per_goal = Decimal.div(remaining_amount, Decimal.new(length(goals)))
      Enum.reduce(goals, %{}, fn goal, acc ->
        Map.put(acc, goal.name, per_goal)
      end)
    else
      %{"Savings" => remaining_amount}
    end
  end
end
