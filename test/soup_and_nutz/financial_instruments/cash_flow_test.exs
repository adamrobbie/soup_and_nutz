defmodule SoupAndNutz.FinancialInstruments.CashFlowTest do
  use SoupAndNutz.DataCase, async: true
  alias SoupAndNutz.FinancialInstruments.CashFlow
  alias SoupAndNutz.XBRL.Concepts

  @valid_attrs %{
    cash_flow_identifier: "TEST_CF_001",
    cash_flow_name: "Test Salary",
    cash_flow_type: "Income",
    cash_flow_category: "Salary",
    cash_flow_subcategory: "Base Salary",
    amount: Decimal.new("5000.00"),
    currency_code: "USD",
    transaction_date: ~D[2024-12-31],
    effective_date: ~D[2024-12-31],
    reporting_period: "2024-12",
    reporting_entity: "TEST_ENTITY",
    reporting_scenario: "Actual",
    frequency: "Monthly",
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-01-31],
    source_account: "Employer Bank",
    payment_method: "BankTransfer",
    description: "Monthly salary payment",
    is_active: true,
    priority_level: "High",
    importance_level: "Essential"
  }

  @invalid_attrs %{
    cash_flow_identifier: nil,
    cash_flow_name: nil,
    cash_flow_type: nil,
    cash_flow_category: nil,
    amount: nil,
    currency_code: nil,
    transaction_date: nil,
    effective_date: nil,
    reporting_period: nil,
    reporting_entity: nil
  }

  test "changeset with valid attributes" do
    changeset = CashFlow.changeset(%CashFlow{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = CashFlow.changeset(%CashFlow{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset requires cash_flow_identifier" do
    attrs = Map.delete(@valid_attrs, :cash_flow_identifier)
    changeset = CashFlow.changeset(%CashFlow{}, attrs)
    refute changeset.valid?
    assert %{cash_flow_identifier: ["can't be blank"]} = errors_on(changeset)
  end

  test "changeset validates cash_flow_type inclusion" do
    attrs = Map.put(@valid_attrs, :cash_flow_type, "InvalidType")
    changeset = CashFlow.changeset(%CashFlow{}, attrs)
    refute changeset.valid?
    assert %{cash_flow_type: ["is invalid"]} = errors_on(changeset)
  end

  test "changeset validates currency_code inclusion" do
    attrs = Map.put(@valid_attrs, :currency_code, "INVALID")
    changeset = CashFlow.changeset(%CashFlow{}, attrs)
    refute changeset.valid?
    assert %{currency_code: ["is invalid"]} = errors_on(changeset)
  end

  test "changeset validates amount is positive" do
    attrs = Map.put(@valid_attrs, :amount, Decimal.new("-100.00"))
    changeset = CashFlow.changeset(%CashFlow{}, attrs)
    refute changeset.valid?
    assert %{amount: ["must be greater than 0"]} = errors_on(changeset)
  end

  test "changeset validates cash_flow_identifier format" do
    attrs = Map.put(@valid_attrs, :cash_flow_identifier, "invalid-identifier")
    changeset = CashFlow.changeset(%CashFlow{}, attrs)
    refute changeset.valid?
    assert %{cash_flow_identifier: ["must contain only uppercase letters, numbers, underscores, and hyphens"]} = errors_on(changeset)
  end

  test "changeset validates effective_date is not before transaction_date" do
    attrs = Map.put(@valid_attrs, :effective_date, ~D[2024-12-30])
    changeset = CashFlow.changeset(%CashFlow{}, attrs)
    refute changeset.valid?
    assert %{effective_date: ["Effective date cannot be before transaction date"]} = errors_on(changeset)
  end

  test "changeset validates recurring fields when is_recurring is true" do
    attrs = Map.put(@valid_attrs, :is_recurring, true)
    attrs = Map.delete(attrs, :recurrence_pattern)
    changeset = CashFlow.changeset(%CashFlow{}, attrs)
    refute changeset.valid?
    assert %{recurrence_pattern: ["can't be blank"]} = errors_on(changeset)
  end

  test "cash_flow_types/0 returns valid types" do
    types = CashFlow.cash_flow_types()
    assert "Income" in types
    assert "Expense" in types
    assert length(types) == 2
  end

  test "cash_flow_categories/0 returns valid categories" do
    categories = CashFlow.cash_flow_categories()
    assert Map.has_key?(categories, "Income")
    assert Map.has_key?(categories, "Expense")
    assert "Salary" in categories["Income"]
    assert "Housing" in categories["Expense"]
  end

  test "cash_flow_frequencies/0 returns valid frequencies" do
    frequencies = CashFlow.cash_flow_frequencies()
    assert "OneTime" in frequencies
    assert "Monthly" in frequencies
    assert "Annually" in frequencies
  end

  test "payment_methods/0 returns valid methods" do
    methods = CashFlow.payment_methods()
    assert "Cash" in methods
    assert "CreditCard" in methods
    assert "BankTransfer" in methods
  end

  test "importance_levels/0 returns valid levels" do
    levels = CashFlow.importance_levels()
    assert "Essential" in levels
    assert "Important" in levels
    assert "Luxury" in levels
  end

  test "total_income/4 calculates total income correctly" do
    income_flows = [
      %CashFlow{
        cash_flow_type: "Income",
        reporting_period: "2024-12",
        reporting_entity: "TEST_ENTITY",
        currency_code: "USD",
        is_active: true,
        amount: Decimal.new("5000.00")
      },
      %CashFlow{
        cash_flow_type: "Income",
        reporting_period: "2024-12",
        reporting_entity: "TEST_ENTITY",
        currency_code: "USD",
        is_active: true,
        amount: Decimal.new("1000.00")
      }
    ]

    total = CashFlow.total_income(income_flows, "2024-12", "TEST_ENTITY", "USD")
    assert Decimal.eq?(total, Decimal.new("6000.00"))
  end

  test "total_expenses/4 calculates total expenses correctly" do
    expense_flows = [
      %CashFlow{
        cash_flow_type: "Expense",
        reporting_period: "2024-12",
        reporting_entity: "TEST_ENTITY",
        currency_code: "USD",
        is_active: true,
        amount: Decimal.new("2000.00")
      },
      %CashFlow{
        cash_flow_type: "Expense",
        reporting_period: "2024-12",
        reporting_entity: "TEST_ENTITY",
        currency_code: "USD",
        is_active: true,
        amount: Decimal.new("500.00")
      }
    ]

    total = CashFlow.total_expenses(expense_flows, "2024-12", "TEST_ENTITY", "USD")
    assert Decimal.eq?(total, Decimal.new("2500.00"))
  end

  test "net_cash_flow/4 calculates net cash flow correctly" do
    cash_flows = [
      %CashFlow{
        cash_flow_type: "Income",
        reporting_period: "2024-12",
        reporting_entity: "TEST_ENTITY",
        currency_code: "USD",
        is_active: true,
        amount: Decimal.new("5000.00")
      },
      %CashFlow{
        cash_flow_type: "Expense",
        reporting_period: "2024-12",
        reporting_entity: "TEST_ENTITY",
        currency_code: "USD",
        is_active: true,
        amount: Decimal.new("3000.00")
      }
    ]

    net = CashFlow.net_cash_flow(cash_flows, "2024-12", "TEST_ENTITY", "USD")
    assert Decimal.eq?(net, Decimal.new("2000.00"))
  end

  test "group_by_category/2 groups cash flows by category" do
    cash_flows = [
      %CashFlow{
        cash_flow_type: "Income",
        cash_flow_category: "Salary",
        amount: Decimal.new("5000.00")
      },
      %CashFlow{
        cash_flow_type: "Income",
        cash_flow_category: "Salary",
        amount: Decimal.new("1000.00")
      },
      %CashFlow{
        cash_flow_type: "Expense",
        cash_flow_category: "Housing",
        amount: Decimal.new("2000.00")
      }
    ]

    income_groups = CashFlow.group_by_category(cash_flows, "Income")
    assert length(income_groups) == 1
    {category, %{total: total}} = List.first(income_groups)
    assert category == "Salary"
    assert Decimal.eq?(total, Decimal.new("6000.00"))
  end

  test "validate_cash_flow_rules/1 validates business rules" do
    # Test valid cash flow
    valid_cash_flow = %CashFlow{
      cash_flow_type: "Income",
      amount: Decimal.new("1000.00"),
      transaction_date: ~D[2024-12-31],
      next_occurrence_date: ~D[2025-01-31],
      is_recurring: true
    }

    {valid, errors} = CashFlow.validate_cash_flow_rules(valid_cash_flow)
    assert valid
    assert errors == []

    # Test invalid cash flow (negative income)
    invalid_cash_flow = %CashFlow{
      cash_flow_type: "Income",
      amount: Decimal.new("-1000.00")
    }

    {valid, errors} = CashFlow.validate_cash_flow_rules(invalid_cash_flow)
    refute valid
    assert length(errors) > 0
  end
end
