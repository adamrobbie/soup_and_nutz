defmodule SoupAndNutz.DebtPayoffPlanner do
  @moduledoc """
  Comprehensive debt payoff planning and strategy optimization.

  This module provides debt payoff calculations, strategy comparisons,
  and optimization recommendations for different debt payoff approaches.
  """

  import Ecto.Query, warn: false
  alias SoupAndNutz.{FinancialInstruments, Repo}
  alias SoupAndNutz.FinancialInstruments.DebtObligation

  @doc """
  Calculates debt payoff using the snowball method (smallest balance first).
  """
  def calculate_snowball_payoff(debts, extra_payment \\ Decimal.new("0")) do
    # Sort by outstanding balance (smallest first)
    sorted_debts = Enum.sort_by(debts, &Decimal.to_float(&1.outstanding_balance))

    calculate_payoff_schedule(sorted_debts, extra_payment, "snowball")
  end

  @doc """
  Calculates debt payoff using the avalanche method (highest interest rate first).
  """
  def calculate_avalanche_payoff(debts, extra_payment \\ Decimal.new("0")) do
    # Sort by interest rate (highest first)
    sorted_debts = Enum.sort_by(debts, &Decimal.to_float(&1.interest_rate), :desc)

    calculate_payoff_schedule(sorted_debts, extra_payment, "avalanche")
  end

  @doc """
  Calculates debt payoff using a custom priority strategy.
  """
  def calculate_custom_payoff(debts, extra_payment \\ Decimal.new("0"), priority_field \\ :priority_level) do
    # Sort by custom priority (High, Medium, Low)
    priority_order = %{"High" => 1, "Medium" => 2, "Low" => 3}

    sorted_debts = Enum.sort_by(debts, fn debt ->
      priority_value = Map.get(debt, priority_field, "Medium")
      Map.get(priority_order, priority_value, 2)
    end)

    calculate_payoff_schedule(sorted_debts, extra_payment, "custom")
  end

  @doc """
  Compares all debt payoff strategies and recommends the best approach.
  """
  def compare_strategies(debts, extra_payment \\ Decimal.new("0")) do
    snowball = calculate_snowball_payoff(debts, extra_payment)
    avalanche = calculate_avalanche_payoff(debts, extra_payment)
    custom = calculate_custom_payoff(debts, extra_payment)

    strategies = [
      %{name: "Snowball", data: snowball, description: "Pay smallest balances first"},
      %{name: "Avalanche", data: avalanche, description: "Pay highest interest rates first"},
      %{name: "Custom", data: custom, description: "Pay based on priority levels"}
    ]

    # Determine best strategy based on total interest and time
    best_strategy = Enum.min_by(strategies, fn strategy ->
      Decimal.to_float(strategy.data.total_interest_paid)
    end)

    fastest_strategy = Enum.min_by(strategies, fn strategy ->
      strategy.data.total_months_to_payoff
    end)

    %{
      strategies: strategies,
      best_financial: best_strategy,
      fastest_payoff: fastest_strategy,
      comparison: create_strategy_comparison(strategies),
      recommendation: generate_strategy_recommendation(strategies, debts)
    }
  end

  @doc """
  Calculates the impact of different extra payment amounts.
  """
  def analyze_extra_payment_impact(debts, payment_amounts \\ [50, 100, 200, 500]) do
    base_payoff = calculate_avalanche_payoff(debts, Decimal.new("0"))

    impact_analysis = Enum.map(payment_amounts, fn amount ->
      extra_decimal = Decimal.new(amount)
      payoff_with_extra = calculate_avalanche_payoff(debts, extra_decimal)

      time_savings = base_payoff.total_months_to_payoff - payoff_with_extra.total_months_to_payoff
      interest_savings = Decimal.sub(base_payoff.total_interest_paid, payoff_with_extra.total_interest_paid)

      %{
        extra_payment: extra_decimal,
        months_saved: time_savings,
        interest_saved: interest_savings,
        total_months: payoff_with_extra.total_months_to_payoff,
        total_interest: payoff_with_extra.total_interest_paid,
        roi_percentage: calculate_roi_percentage(extra_decimal, interest_savings, time_savings)
      }
    end)

    %{
      base_scenario: base_payoff,
      extra_payment_scenarios: impact_analysis,
      recommended_extra_payment: find_optimal_extra_payment(impact_analysis)
    }
  end

  @doc """
  Generates a month-by-month debt payoff schedule.
  """
  def generate_payoff_schedule(debts, strategy \\ "avalanche", extra_payment \\ Decimal.new("0")) do
    payoff_data = case strategy do
      "snowball" -> calculate_snowball_payoff(debts, extra_payment)
      "avalanche" -> calculate_avalanche_payoff(debts, extra_payment)
      "custom" -> calculate_custom_payoff(debts, extra_payment)
    end

    # Generate detailed month-by-month schedule
    schedule = build_detailed_schedule(debts, payoff_data, extra_payment)

    %{
      strategy: strategy,
      extra_payment: extra_payment,
      summary: payoff_data,
      monthly_schedule: schedule,
      milestones: identify_payoff_milestones(schedule)
    }
  end

  @doc """
  Calculates debt consolidation benefits.
  """
  def analyze_consolidation_options(debts, consolidation_rate, consolidation_term_months) do
    current_payoff = calculate_avalanche_payoff(debts)

    total_debt = Enum.reduce(debts, Decimal.new("0"), fn debt, acc ->
      Decimal.add(acc, debt.outstanding_balance)
    end)

    # Calculate consolidation loan payment
    monthly_rate = Decimal.div(consolidation_rate, Decimal.new("1200"))  # Annual to monthly
    consolidation_payment = calculate_loan_payment(total_debt, monthly_rate, consolidation_term_months)

    total_consolidation_payments = Decimal.mult(consolidation_payment, Decimal.new(consolidation_term_months))
    total_consolidation_interest = Decimal.sub(total_consolidation_payments, total_debt)

    %{
      current_scenario: current_payoff,
      consolidation_scenario: %{
        loan_amount: total_debt,
        interest_rate: consolidation_rate,
        term_months: consolidation_term_months,
        monthly_payment: consolidation_payment,
        total_payments: total_consolidation_payments,
        total_interest: total_consolidation_interest
      },
      savings: %{
        interest_savings: Decimal.sub(current_payoff.total_interest_paid, total_consolidation_interest),
        monthly_payment_difference: Decimal.sub(current_payoff.total_monthly_payments, consolidation_payment),
        time_difference: current_payoff.total_months_to_payoff - consolidation_term_months
      },
      recommendation: recommend_consolidation(current_payoff, total_consolidation_interest, consolidation_term_months)
    }
  end

  # Private helper functions

  defp calculate_payoff_schedule(sorted_debts, extra_payment, strategy_name) do
    total_minimum_payments = Enum.reduce(sorted_debts, Decimal.new("0"), fn debt, acc ->
      Decimal.add(acc, debt.monthly_payment || Decimal.new("0"))
    end)

    available_extra = extra_payment
    payoff_order = []
    total_interest = Decimal.new("0")
    current_month = 0

    # Simulate payoff process
    {final_order, final_interest, final_months} = simulate_payoff(
      sorted_debts,
      available_extra,
      total_minimum_payments
    )

    %{
      strategy: strategy_name,
      payoff_order: final_order,
      total_months_to_payoff: final_months,
      total_interest_paid: final_interest,
      total_monthly_payments: total_minimum_payments,
      extra_payment_used: extra_payment,
      debt_count: length(sorted_debts)
    }
  end

  defp simulate_payoff(debts, extra_payment, total_minimum) do
    # Simplified simulation - in a real implementation, this would be more detailed
    total_balance = Enum.reduce(debts, Decimal.new("0"), fn debt, acc ->
      Decimal.add(acc, debt.outstanding_balance)
    end)

    # Estimate average interest rate
    avg_interest_rate = calculate_weighted_average_rate(debts)

    # Calculate total months using standard loan formula with extra payments
    total_monthly_payment = Decimal.add(total_minimum, extra_payment)

    months_to_payoff = if Decimal.gt?(total_monthly_payment, Decimal.new("0")) do
      calculate_payoff_time(total_balance, avg_interest_rate, total_monthly_payment)
    else
      999  # Infinite if no payments
    end

    # Estimate total interest (simplified)
    total_payments = Decimal.mult(total_monthly_payment, Decimal.new(months_to_payoff))
    total_interest = Decimal.sub(total_payments, total_balance)

    payoff_order = Enum.with_index(debts, 1)
    |> Enum.map(fn {debt, index} ->
      %{
        debt_name: debt.debt_name,
        balance: debt.outstanding_balance,
        interest_rate: debt.interest_rate,
        order: index
      }
    end)

    {payoff_order, total_interest, months_to_payoff}
  end

  defp calculate_weighted_average_rate(debts) do
    total_balance = Enum.reduce(debts, Decimal.new("0"), fn debt, acc ->
      Decimal.add(acc, debt.outstanding_balance)
    end)

    if Decimal.gt?(total_balance, Decimal.new("0")) do
      weighted_sum = Enum.reduce(debts, Decimal.new("0"), fn debt, acc ->
        weight = Decimal.mult(debt.outstanding_balance, debt.interest_rate)
        Decimal.add(acc, weight)
      end)

      Decimal.div(weighted_sum, total_balance)
    else
      Decimal.new("0")
    end
  end

  defp calculate_payoff_time(balance, annual_rate, monthly_payment) do
    monthly_rate = Decimal.div(annual_rate, Decimal.new("1200"))

    if Decimal.gt?(monthly_rate, Decimal.new("0")) do
      # Use loan payoff formula: n = -log(1 - (P*r/M)) / log(1 + r)
      # Simplified approximation for now
      rate_float = Decimal.to_float(monthly_rate)
      balance_float = Decimal.to_float(balance)
      payment_float = Decimal.to_float(monthly_payment)

      if payment_float > balance_float * rate_float do
        numerator = :math.log(1 - (balance_float * rate_float / payment_float))
        denominator = :math.log(1 + rate_float)
        round(-numerator / denominator)
      else
        999  # Payment too small to ever pay off
      end
    else
      # No interest, simple division
      balance_float = Decimal.to_float(balance)
      payment_float = Decimal.to_float(monthly_payment)
      round(balance_float / payment_float)
    end
  end

  defp calculate_loan_payment(principal, monthly_rate, term_months) do
    if Decimal.gt?(monthly_rate, Decimal.new("0")) do
      # Standard loan payment formula: M = P * [r(1+r)^n] / [(1+r)^n - 1]
      rate_float = Decimal.to_float(monthly_rate)
      principal_float = Decimal.to_float(principal)

      numerator = rate_float * :math.pow(1 + rate_float, term_months)
      denominator = :math.pow(1 + rate_float, term_months) - 1

      payment = principal_float * (numerator / denominator)
      Decimal.from_float(payment)
    else
      # No interest, simple division
      Decimal.div(principal, Decimal.new(term_months))
    end
  end

  defp create_strategy_comparison(strategies) do
    Enum.map(strategies, fn strategy ->
      %{
        name: strategy.name,
        total_interest: strategy.data.total_interest_paid,
        total_months: strategy.data.total_months_to_payoff,
        description: strategy.description
      }
    end)
  end

  defp generate_strategy_recommendation(strategies, debts) do
    debt_count = length(debts)
    total_debt = Enum.reduce(debts, Decimal.new("0"), fn debt, acc ->
      Decimal.add(acc, debt.outstanding_balance)
    end)

    cond do
      debt_count <= 2 ->
        "With only #{debt_count} debts, the Avalanche method will save the most money on interest."

      Decimal.lt?(total_debt, Decimal.new("10000")) ->
        "For smaller debt amounts, the Snowball method can provide psychological wins and momentum."

      true ->
        "The Avalanche method is recommended for maximum interest savings on larger debt amounts."
    end
  end

  defp calculate_roi_percentage(extra_payment, interest_saved, months_saved) do
    if Decimal.gt?(extra_payment, Decimal.new("0")) and months_saved > 0 do
      total_extra_paid = Decimal.mult(extra_payment, Decimal.new(months_saved))
      if Decimal.gt?(total_extra_paid, Decimal.new("0")) do
        roi = Decimal.div(interest_saved, total_extra_paid)
        Decimal.mult(roi, Decimal.new("100"))
      else
        Decimal.new("0")
      end
    else
      Decimal.new("0")
    end
  end

  defp find_optimal_extra_payment(impact_analysis) do
    # Find the extra payment with the best ROI
    Enum.max_by(impact_analysis, fn scenario ->
      Decimal.to_float(scenario.roi_percentage)
    end)
  end

  defp build_detailed_schedule(debts, payoff_data, extra_payment) do
    # Generate month-by-month schedule
    # This is a simplified version - a full implementation would track each debt separately
    Enum.map(1..payoff_data.total_months_to_payoff, fn month ->
      %{
        month: month,
        total_payment: Decimal.add(payoff_data.total_monthly_payments, extra_payment),
        remaining_balance: Decimal.new("0"),  # Would calculate actual remaining balance
        interest_paid: Decimal.new("0"),      # Would calculate monthly interest
        principal_paid: Decimal.new("0")      # Would calculate monthly principal
      }
    end)
  end

  defp identify_payoff_milestones(schedule) do
    total_months = length(schedule)

    [
      %{milestone: "25% Complete", month: round(total_months * 0.25)},
      %{milestone: "50% Complete", month: round(total_months * 0.50)},
      %{milestone: "75% Complete", month: round(total_months * 0.75)},
      %{milestone: "Debt Free!", month: total_months}
    ]
  end

  defp recommend_consolidation(current_payoff, consolidation_interest, consolidation_months) do
    interest_savings = Decimal.sub(current_payoff.total_interest_paid, consolidation_interest)
    time_savings = current_payoff.total_months_to_payoff - consolidation_months

    cond do
      Decimal.gt?(interest_savings, Decimal.new("1000")) and time_savings > 12 ->
        "Highly recommended - significant savings in both interest and time"

      Decimal.gt?(interest_savings, Decimal.new("500")) ->
        "Recommended - good interest savings"

      time_savings > 6 ->
        "Consider - faster payoff but check fees"

      true ->
        "Not recommended - minimal benefits"
    end
  end
end
