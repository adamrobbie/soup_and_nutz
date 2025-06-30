defmodule SoupAndNutzWeb.Services.ChartDataService do
  @moduledoc """
  Service for transforming financial data into chart-ready formats.

  This service provides functions to convert various financial data structures
  into the standardized format expected by the chart components.
  """

  alias SoupAndNutz.BudgetPlanner
  alias SoupAndNutz.DebtPayoffPlanner
  alias SoupAndNutz.FinancialAnalysis

  @doc """
  Prepares debt payoff strategy comparison data for a bar chart.
  """
  def prepare_debt_strategy_comparison(debts) do
    comparison = DebtPayoffPlanner.compare_strategies(debts)

    %{
      labels: Enum.map(comparison.strategies, & &1.name),
      datasets: [
        %{
          label: "Total Interest Paid",
          data: Enum.map(comparison.strategies, fn strategy ->
            Decimal.to_float(strategy.data.total_interest_paid)
          end),
          backgroundColor: "#EF4444",
          borderColor: "#DC2626"
        },
        %{
          label: "Months to Payoff",
          data: Enum.map(comparison.strategies, fn strategy ->
            strategy.data.total_months_to_payoff
          end),
          backgroundColor: "#3B82F6",
          borderColor: "#2563EB"
        }
      ]
    }
  end

  @doc """
  Prepares extra payment impact data for a line chart.
  """
  def prepare_extra_payment_impact(debts, extra_payments) do
    analysis = DebtPayoffPlanner.analyze_extra_payment_impact(debts, extra_payments)

    %{
      labels: Enum.map(analysis.extra_payment_scenarios, fn scenario ->
        "$#{Decimal.to_string(scenario.extra_payment)}/mo"
      end),
      datasets: [
        %{
          label: "Months to Payoff",
          data: Enum.map(analysis.extra_payment_scenarios, & &1.total_months),
          borderColor: "#3B82F6",
          backgroundColor: "rgba(59, 130, 246, 0.1)",
          fill: true
        },
        %{
          label: "Interest Saved",
          data: Enum.map(analysis.extra_payment_scenarios, fn scenario ->
            Decimal.to_float(scenario.interest_saved)
          end),
          borderColor: "#10B981",
          backgroundColor: "rgba(16, 185, 129, 0.1)",
          fill: false
        }
      ]
    }
  end

  @doc """
  Prepares debt breakdown data for a pie chart.
  """
  def prepare_debt_breakdown(debts) do
    %{
      labels: Enum.map(debts, & &1.debt_name),
      values: Enum.map(debts, fn debt ->
        Decimal.to_float(debt.outstanding_balance)
      end)
    }
  end

  @doc """
  Prepares asset allocation data for a doughnut chart.
  """
  def prepare_asset_allocation(assets) do
    %{
      labels: Enum.map(assets, & &1.asset_name),
      values: Enum.map(assets, fn asset ->
        Decimal.to_float(asset.current_value)
      end)
    }
  end

  @doc """
  Prepares net worth over time data for a line chart.
  """
  def prepare_net_worth_timeline(snapshots) do
    %{
      labels: Enum.map(snapshots, fn snapshot ->
        Calendar.strftime(snapshot.snapshot_date, "%b %Y")
      end),
      datasets: [
        %{
          label: "Net Worth",
          data: Enum.map(snapshots, fn snapshot ->
            Decimal.to_float(snapshot.net_worth)
          end),
          borderColor: "#10B981",
          backgroundColor: "rgba(16, 185, 129, 0.1)",
          fill: true
        }
      ]
    }
  end

  @doc """
  Prepares cash flow data for a stacked bar chart.
  """
  def prepare_cash_flow_breakdown(cash_flows, period \\ "monthly") do
    grouped_flows = group_cash_flows_by_period(cash_flows, period)

    %{
      labels: Enum.map(grouped_flows, & &1.period),
      datasets: [
        %{
          label: "Income",
          data: Enum.map(grouped_flows, fn group ->
            Decimal.to_float(group.total_income)
          end),
          backgroundColor: "#10B981",
          borderColor: "#059669",
          stack: "stack"
        },
        %{
          label: "Expenses",
          data: Enum.map(grouped_flows, fn group ->
            Decimal.to_float(group.total_expenses)
          end),
          backgroundColor: "#EF4444",
          borderColor: "#DC2626",
          stack: "stack"
        }
      ]
    }
  end

  @doc """
  Prepares budget performance data for a bar chart.
  """
  def prepare_budget_performance(budget_data) do
    performance = BudgetPlanner.analyze_budget_performance(budget_data.user_id, budget_data.period, budget_data.currency)

    %{
      labels: Enum.map(performance.category_performance, & &1.category),
      datasets: [
        %{
          label: "Budgeted",
          data: Enum.map(performance.category_performance, fn cat ->
            Decimal.to_float(cat.budgeted_amount)
          end),
          backgroundColor: "#3B82F6",
          borderColor: "#2563EB"
        },
        %{
          label: "Actual",
          data: Enum.map(performance.category_performance, fn cat ->
            Decimal.to_float(cat.actual_amount)
          end),
          backgroundColor: "#10B981",
          borderColor: "#059669"
        }
      ]
    }
  end

  @doc """
  Prepares debt payoff timeline data for a line chart.
  """
  def prepare_debt_payoff_timeline(debts, _strategy \\ "avalanche", extra_payment \\ Decimal.new("0")) do
    schedule = DebtPayoffPlanner.calculate_avalanche_payoff(debts, extra_payment)

    %{
      labels: Enum.map(Map.get(schedule, :monthly_breakdown, []), fn month ->
        "Month #{month.month}"
      end),
      datasets: [
        %{
          label: "Remaining Debt",
          data: Enum.map(Map.get(schedule, :monthly_breakdown, []), fn month ->
            Decimal.to_float(month.remaining_debt)
          end),
          borderColor: "#EF4444",
          backgroundColor: "rgba(239, 68, 68, 0.1)",
          fill: true
        },
        %{
          label: "Interest Paid",
          data: Enum.map(Map.get(schedule, :monthly_breakdown, []), fn month ->
            Decimal.to_float(month.interest_paid)
          end),
          borderColor: "#F59E0B",
          backgroundColor: "rgba(245, 158, 11, 0.1)",
          fill: false
        }
      ]
    }
  end

  @doc """
  Prepares financial health metrics data for a radar chart.
  """
  def prepare_financial_health_radar(_assets, _debts, _cash_flows) do
    analysis = FinancialAnalysis.generate_financial_health_report(1, "2025-01", "USD")

    %{
      labels: ["Debt-to-Income", "Savings Rate", "Emergency Fund", "Investment Ratio", "Cash Flow"],
      datasets: [
        %{
          label: "Current Score",
          data: [
            analysis.debt_to_asset_ratio,
            analysis.savings_rate,
            analysis.emergency_fund_adequacy,
            analysis.investment_ratio,
            analysis.liquidity_ratio
          ],
          borderColor: "#3B82F6",
          backgroundColor: "rgba(59, 130, 246, 0.2)",
          fill: true
        }
      ]
    }
  end

  @doc """
  Prepares monthly spending trends data for a line chart.
  """
  def prepare_spending_trends(cash_flows, months \\ 12) do
    recent_flows = Enum.take(cash_flows, months)

    %{
      labels: Enum.map(recent_flows, fn flow ->
        Calendar.strftime(flow.flow_date, "%b %Y")
      end),
      datasets: [
        %{
          label: "Total Spending",
          data: Enum.map(recent_flows, fn flow ->
            Decimal.to_float(flow.amount)
          end),
          borderColor: "#EF4444",
          backgroundColor: "rgba(239, 68, 68, 0.1)",
          fill: true
        }
      ]
    }
  end

  # Private helper functions

  defp group_cash_flows_by_period(cash_flows, "monthly") do
    cash_flows
    |> Enum.group_by(fn flow ->
      {flow.flow_date.year, flow.flow_date.month}
    end)
    |> Enum.map(fn {{year, month}, flows} ->
      total_income = Enum.filter(flows, & &1.flow_type == "income")
      |> Enum.reduce(Decimal.new("0"), fn flow, acc ->
        Decimal.add(acc, flow.amount)
      end)

      total_expenses = Enum.filter(flows, & &1.flow_type == "expense")
      |> Enum.reduce(Decimal.new("0"), fn flow, acc ->
        Decimal.add(acc, flow.amount)
      end)

      %{
        period: Calendar.strftime(Date.new!(year, month, 1), "%b %Y"),
        total_income: total_income,
        total_expenses: total_expenses
      }
    end)
    |> Enum.sort_by(& &1.period)
  end

  defp group_cash_flows_by_period(cash_flows, "quarterly") do
    cash_flows
    |> Enum.group_by(fn flow ->
      {flow.flow_date.year, ceil(flow.flow_date.month / 3)}
    end)
    |> Enum.map(fn {{year, quarter}, flows} ->
      total_income = Enum.filter(flows, & &1.flow_type == "income")
      |> Enum.reduce(Decimal.new("0"), fn flow, acc ->
        Decimal.add(acc, flow.amount)
      end)

      total_expenses = Enum.filter(flows, & &1.flow_type == "expense")
      |> Enum.reduce(Decimal.new("0"), fn flow, acc ->
        Decimal.add(acc, flow.amount)
      end)

      %{
        period: "Q#{quarter} #{year}",
        total_income: total_income,
        total_expenses: total_expenses
      }
    end)
    |> Enum.sort_by(& &1.period)
  end
end
