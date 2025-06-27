defmodule SoupAndNutz.DebtPayoffPlannerTest do
  use SoupAndNutz.DataCase
  alias SoupAndNutz.DebtPayoffPlanner
  alias SoupAndNutz.FinancialInstrumentsFixtures

  describe "calculate_snowball_payoff/2" do
    test "calculates snowball payoff with smallest balance first" do
      # Create debts with different balances (smallest first for snowball)
      small_debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{
        outstanding_balance: "1000.00",
        interest_rate: "5.0",
        monthly_payment: "100.00",
        debt_name: "Small Credit Card"
      })

      large_debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{
        outstanding_balance: "5000.00",
        interest_rate: "3.0",
        monthly_payment: "200.00",
        debt_name: "Car Loan"
      })

      debts = [large_debt, small_debt]  # Not in order
      extra_payment = Decimal.new("50.00")

      result = DebtPayoffPlanner.calculate_snowball_payoff(debts, extra_payment)

      assert result.strategy == "snowball"
      assert result.extra_payment_used == extra_payment
      assert result.debt_count == 2
      assert is_list(result.payoff_order)
      assert is_integer(result.total_months_to_payoff)
      assert Decimal.gt?(result.total_interest_paid, Decimal.new("0"))
      assert Decimal.gt?(result.total_monthly_payments, Decimal.new("0"))

      # Check that smallest debt is first in payoff order
      first_debt = List.first(result.payoff_order)
      assert first_debt.debt_name == "Small Credit Card"
    end
  end

  describe "calculate_avalanche_payoff/2" do
    test "calculates avalanche payoff with highest interest first" do
      # Create debts with different interest rates (highest first for avalanche)
      high_interest = FinancialInstrumentsFixtures.debt_obligation_fixture(%{
        outstanding_balance: "3000.00",
        interest_rate: "18.0",
        monthly_payment: "150.00",
        debt_name: "Credit Card"
      })

      low_interest = FinancialInstrumentsFixtures.debt_obligation_fixture(%{
        outstanding_balance: "2000.00",
        interest_rate: "4.0",
        monthly_payment: "100.00",
        debt_name: "Student Loan"
      })

      debts = [low_interest, high_interest]  # Not in order
      extra_payment = Decimal.new("75.00")

      result = DebtPayoffPlanner.calculate_avalanche_payoff(debts, extra_payment)

      assert result.strategy == "avalanche"
      assert result.extra_payment_used == extra_payment
      assert result.debt_count == 2
      assert is_list(result.payoff_order)
      assert is_integer(result.total_months_to_payoff)
      assert Decimal.gt?(result.total_interest_paid, Decimal.new("0"))

      # Check that highest interest debt is first in payoff order
      first_debt = List.first(result.payoff_order)
      assert first_debt.debt_name == "Credit Card"
    end
  end

  describe "calculate_custom_payoff/3" do
    test "calculates custom payoff based on priority levels" do
      high_priority = FinancialInstrumentsFixtures.debt_obligation_fixture(%{
        outstanding_balance: "4000.00",
        interest_rate: "6.0",
        monthly_payment: "200.00",
        debt_name: "High Priority Debt",
        priority_level: "High"
      })

      low_priority = FinancialInstrumentsFixtures.debt_obligation_fixture(%{
        outstanding_balance: "1500.00",
        interest_rate: "8.0",
        monthly_payment: "75.00",
        debt_name: "Low Priority Debt",
        priority_level: "Low"
      })

      debts = [low_priority, high_priority]  # Not in order
      extra_payment = Decimal.new("25.00")

      result = DebtPayoffPlanner.calculate_custom_payoff(debts, extra_payment)

      assert result.strategy == "custom"
      assert result.extra_payment_used == extra_payment
      assert result.debt_count == 2
      assert is_list(result.payoff_order)

      # Check that high priority debt is first in payoff order
      first_debt = List.first(result.payoff_order)
      assert first_debt.debt_name == "High Priority Debt"
    end
  end

  describe "compare_strategies/2" do
    test "compares all debt payoff strategies" do
      debt1 = FinancialInstrumentsFixtures.debt_obligation_fixture(%{
        outstanding_balance: "2000.00",
        interest_rate: "15.0",
        monthly_payment: "100.00",
        debt_name: "High Interest Card",
        priority_level: "Medium"
      })

      debt2 = FinancialInstrumentsFixtures.debt_obligation_fixture(%{
        outstanding_balance: "800.00",
        interest_rate: "5.0",
        monthly_payment: "50.00",
        debt_name: "Small Loan",
        priority_level: "Low"
      })

      debts = [debt1, debt2]
      extra_payment = Decimal.new("100.00")

      result = DebtPayoffPlanner.compare_strategies(debts, extra_payment)

      assert is_list(result.strategies)
      assert length(result.strategies) == 3  # Snowball, Avalanche, Custom
      assert is_map(result.best_financial)
      assert is_map(result.fastest_payoff)
      assert is_list(result.comparison)
      assert is_binary(result.recommendation)

      # Check that all strategies are present
      strategy_names = Enum.map(result.strategies, & &1.name)
      assert "Snowball" in strategy_names
      assert "Avalanche" in strategy_names
      assert "Custom" in strategy_names
    end
  end

  describe "analyze_extra_payment_impact/2" do
    test "analyzes impact of different extra payment amounts" do
      debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{
        outstanding_balance: "10000.00",
        principal_amount: "12000.00",  # Must be >= outstanding_balance
        interest_rate: "12.0",
        monthly_payment: "300.00",
        debt_name: "Large Debt"
      })

      debts = [debt]
      payment_amounts = [50, 100, 200]

      result = DebtPayoffPlanner.analyze_extra_payment_impact(debts, payment_amounts)

      assert is_map(result.base_scenario)
      assert is_list(result.extra_payment_scenarios)
      assert length(result.extra_payment_scenarios) == 3
      assert is_map(result.recommended_extra_payment)

      # Check that scenarios have expected structure
      first_scenario = List.first(result.extra_payment_scenarios)
      assert Decimal.eq?(first_scenario.extra_payment, Decimal.new("50"))
      assert is_integer(first_scenario.months_saved)
      assert Decimal.gt?(first_scenario.interest_saved, Decimal.new("0"))
      assert is_integer(first_scenario.total_months)
      assert Decimal.gt?(first_scenario.total_interest, Decimal.new("0"))
      assert Decimal.gt?(first_scenario.roi_percentage, Decimal.new("0"))
    end
  end

  describe "generate_payoff_schedule/3" do
    test "generates detailed month-by-month payoff schedule" do
      debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{
        outstanding_balance: "5000.00",
        interest_rate: "10.0",
        monthly_payment: "200.00",
        debt_name: "Test Debt"
      })

      debts = [debt]
      strategy = "avalanche"
      extra_payment = Decimal.new("50.00")

      result = DebtPayoffPlanner.generate_payoff_schedule(debts, strategy, extra_payment)

      assert result.strategy == strategy
      assert result.extra_payment == extra_payment
      assert is_map(result.summary)
      assert is_list(result.monthly_schedule)
      assert is_list(result.milestones)

      # Check monthly schedule structure
      first_month = List.first(result.monthly_schedule)
      assert first_month.month == 1
      assert Decimal.gt?(first_month.total_payment, Decimal.new("0"))
      assert is_map(first_month)

      # Check milestones structure
      first_milestone = List.first(result.milestones)
      assert is_binary(first_milestone.milestone)
      assert is_integer(first_milestone.month)
    end
  end

  describe "analyze_consolidation_options/3" do
    test "analyzes debt consolidation benefits" do
      debt1 = FinancialInstrumentsFixtures.debt_obligation_fixture(%{
        outstanding_balance: "3000.00",
        interest_rate: "18.0",
        monthly_payment: "150.00",
        debt_name: "High Interest Card"
      })

      debt2 = FinancialInstrumentsFixtures.debt_obligation_fixture(%{
        outstanding_balance: "2000.00",
        interest_rate: "12.0",
        monthly_payment: "100.00",
        debt_name: "Medium Interest Card"
      })

      debts = [debt1, debt2]
      consolidation_rate = Decimal.new("8.0")  # 8% APR
      consolidation_term_months = 36

      result = DebtPayoffPlanner.analyze_consolidation_options(debts, consolidation_rate, consolidation_term_months)

      assert is_map(result.current_scenario)
      assert is_map(result.consolidation_scenario)
      assert is_map(result.savings)
      assert is_binary(result.recommendation)

      # Check consolidation scenario structure
      consolidation = result.consolidation_scenario
      assert Decimal.eq?(consolidation.loan_amount, Decimal.new("5000.00"))
      assert consolidation.interest_rate == consolidation_rate
      assert consolidation.term_months == consolidation_term_months
      assert Decimal.gt?(consolidation.monthly_payment, Decimal.new("0"))
      assert Decimal.gt?(consolidation.total_payments, Decimal.new("0"))
      assert Decimal.gt?(consolidation.total_interest, Decimal.new("0"))

      # Check savings structure
      savings = result.savings
      assert Decimal.gt?(savings.interest_savings, Decimal.new("0"))
      assert is_map(savings)
    end
  end
end
