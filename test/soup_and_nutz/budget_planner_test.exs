defmodule SoupAndNutz.BudgetPlannerTest do
  use SoupAndNutz.DataCase
  alias SoupAndNutz.BudgetPlanner
  alias SoupAndNutz.FinancialInstrumentsFixtures
  alias SoupAndNutz.Factory

  setup do
    user = Factory.insert(:user)
    {:ok, user: user}
  end

  describe "create_budget/4" do
    test "creates 50/30/20 budget with income and expenses", %{user: user} do
      period = "2024-Q1"
      _income = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "4000.00", cash_flow_type: "Income", cash_flow_category: "Salary", currency_code: "USD", user_id: user.id, reporting_period: period})
      _expense = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "1000.00", cash_flow_type: "Expense", cash_flow_category: "Housing", currency_code: "USD", user_id: user.id, reporting_period: period})

      budget = BudgetPlanner.create_budget(user.id, period, "50/30/20")

      assert budget.user_id == user.id
      assert budget.period == period
      assert budget.budget_type == "50/30/20"
      assert budget.total_income == Decimal.new("4000.00")
      assert Map.has_key?(budget.budget_allocation, "Housing")
      assert Map.has_key?(budget.budget_allocation, "Savings")
      assert Decimal.compare(budget.savings_goal, Decimal.new("800.00")) == :eq  # 20% of 4000
    end

    test "creates zero-based budget with historical data", %{user: user} do
      period = "2024-Q1"
      _income = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "3000.00", cash_flow_type: "Income", cash_flow_category: "Salary", currency_code: "USD", user_id: user.id, reporting_period: period})
      _expense = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "800.00", cash_flow_type: "Expense", cash_flow_category: "Housing", currency_code: "USD", user_id: user.id, reporting_period: period})

      budget = BudgetPlanner.create_budget(user.id, period, "zero_based")

      assert budget.budget_type == "zero_based"
      assert budget.total_income == Decimal.new("3000.00")
      assert Map.has_key?(budget.budget_allocation, "Housing")
      assert Map.has_key?(budget.budget_allocation, "Savings")
    end

    test "creates custom budget with goals", %{user: user} do
      period = "2024-Q1"
      goals = [%{name: "Vacation", amount: "1000.00"}]
      _income = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "5000.00", cash_flow_type: "Income", cash_flow_category: "Salary", currency_code: "USD", user_id: user.id, reporting_period: period})

      budget = BudgetPlanner.create_budget(user.id, period, "custom", goals)

      assert budget.budget_type == "custom"
      assert budget.goals == goals
      assert budget.total_income == Decimal.new("5000.00")
      assert Map.has_key?(budget.budget_allocation, "Vacation")
    end
  end

  describe "analyze_budget_performance/3" do
    test "analyzes budget vs actual spending", %{user: user} do
      period = "2024-Q1"

      # Create budget
      _income = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "4000.00", cash_flow_type: "Income", cash_flow_category: "Salary", currency_code: "USD", user_id: user.id, reporting_period: period})
      budget = BudgetPlanner.create_budget(user.id, period, "50/30/20")

      # Create actual spending (over budget in Housing)
      _actual_housing = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "1500.00", cash_flow_type: "Expense", cash_flow_category: "Housing", currency_code: "USD", user_id: user.id, reporting_period: period})
      _actual_food = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "400.00", cash_flow_type: "Expense", cash_flow_category: "Food", currency_code: "USD", user_id: user.id, reporting_period: period})

      performance = BudgetPlanner.analyze_budget_performance(user.id, period, budget)

      assert performance.user_id == user.id
      assert performance.period == period
      assert is_map(performance.overall_performance)
      assert is_list(performance.category_performance)
      assert is_list(performance.recommendations)
      assert is_map(performance.savings_achieved)

      # Check that Housing is over budget
      housing_performance = Enum.find(performance.category_performance, &(&1.category == "Housing"))
      assert housing_performance.status == "over_budget"
    end
  end

  describe "optimize_budget/4" do
    test "generates optimization recommendations", %{user: user} do
      period = "2024-Q1"
      financial_goals = [%{name: "Emergency Fund", target: "10000.00"}]

      # Create budget
      _income = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "4000.00", cash_flow_type: "Income", cash_flow_category: "Salary", currency_code: "USD", user_id: user.id, reporting_period: period})
      budget = BudgetPlanner.create_budget(user.id, period, "50/30/20")

      # Create overspending scenario
      _actual_housing = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "1500.00", cash_flow_type: "Expense", cash_flow_category: "Housing", currency_code: "USD", user_id: user.id, reporting_period: period})

      optimization = BudgetPlanner.optimize_budget(user.id, period, budget, financial_goals)

      assert optimization.user_id == user.id
      assert optimization.period == period
      assert is_map(optimization.current_performance)
      assert is_list(optimization.optimization_suggestions)
      assert is_map(optimization.projected_savings)
      assert is_map(optimization.goal_impact)
    end
  end

  describe "check_budget_alerts/3" do
    test "generates budget alerts for overspending", %{user: user} do
      period = "2024-Q1"

      # Create budget
      _income = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "4000.00", cash_flow_type: "Income", cash_flow_category: "Salary", currency_code: "USD", user_id: user.id, reporting_period: period})
      budget = BudgetPlanner.create_budget(user.id, period, "50/30/20")

      # Create significant overspending to trigger alerts
      _actual_housing = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "2000.00", cash_flow_type: "Expense", cash_flow_category: "Housing", currency_code: "USD", user_id: user.id, reporting_period: period})

      alerts = BudgetPlanner.check_budget_alerts(user.id, period, budget)

      assert alerts.user_id == user.id
      assert alerts.period == period
      assert is_list(alerts.alerts)
      assert is_integer(alerts.alert_count)
      assert alerts.highest_severity in ["none", "low", "medium", "high"]

      # Should have at least one alert for Housing overspending
      assert alerts.alert_count > 0
      housing_alert = Enum.find(alerts.alerts, &(&1.category == "Housing"))
      assert housing_alert.type == "over_budget"
    end
  end
end
