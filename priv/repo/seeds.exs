# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SoupAndNutz.Repo.insert!(%SoupAndNutz.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias SoupAndNutz.FinancialInstruments
alias SoupAndNutz.FinancialInstruments.{Asset, DebtObligation, CashFlow}
alias SoupAndNutz.XBRL.Concepts

# Clear existing data
IO.puts("Clearing existing data...")
SoupAndNutz.Repo.delete_all(Asset)
SoupAndNutz.Repo.delete_all(DebtObligation)
SoupAndNutz.Repo.delete_all(CashFlow)
SoupAndNutz.Repo.delete_all(SoupAndNutz.Accounts.User)

# Helper functions using XBRL concepts
get_currency = fn -> List.first(Concepts.currency_codes()) end
get_payment_frequency = fn -> "Monthly" end
get_validation_status = fn -> "Pending" end
get_scenario_type = fn -> List.first(Concepts.scenario_types()) end
get_cash_flow_frequency = fn -> "Monthly" end
get_payment_method = fn -> "BankTransfer" end
get_priority_level = fn -> "Medium" end
get_importance_level = fn -> "Important" end
get_budget_period = fn -> "Monthly" end
get_tax_category = fn -> "NonDeductible" end

# --- Sample Users ---
users = [
  %{
    email: "alice@example.com",
    username: "alice",
    password: "password123",
    password_confirmation: "password123",
    first_name: "Alice",
    last_name: "Smith",
    preferred_currency: "USD",
    account_type: "Individual",
    subscription_tier: "Free",
    is_active: true
  },
  %{
    email: "bob@example.com",
    username: "bob",
    password: "password123",
    password_confirmation: "password123",
    first_name: "Bob",
    last_name: "Johnson",
    preferred_currency: "USD",
    account_type: "Individual",
    subscription_tier: "Free",
    is_active: true
  },
  %{
    email: "carol@example.com",
    username: "carol",
    password: "password123",
    password_confirmation: "password123",
    first_name: "Carol",
    last_name: "Williams",
    preferred_currency: "USD",
    account_type: "Individual",
    subscription_tier: "Premium",
    is_active: true
  }
]

user_records =
  Enum.map(users, fn attrs ->
    case SoupAndNutz.Accounts.create_user(attrs) do
      {:ok, user} -> user
      {:error, changeset} ->
        IO.inspect(changeset.errors, label: "User creation error")
        nil
    end
  end)
  |> Enum.filter(& &1) # Remove nils if any user creation failed

# Get the first user's ID to associate with all financial data
first_user = List.first(user_records)
second_user = Enum.at(user_records, 1)
third_user = Enum.at(user_records, 2)
user_id = first_user.id

# Family Financial Scenarios - Comprehensive Seed Data

# Scenario 1: Young Family (John & Sarah Smith)
young_family_assets = [
  %{
    user_id: user_id,
    asset_identifier: "CASH_001",
    asset_name: "Joint Checking Account",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Checking",
    asset_value: Decimal.new("8500.00"),
    book_value: Decimal.new("8500.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Primary joint checking account for daily expenses",
    location: "Chase Bank",
    custodian: "Chase Bank",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "High",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "SAVINGS_001",
    asset_name: "Emergency Fund",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Savings",
    asset_value: Decimal.new("25000.00"),
    book_value: Decimal.new("25000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "High-yield savings account for emergency fund",
    location: "Ally Bank",
    custodian: "Ally Bank",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "High",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "401K_JOHN_001",
    asset_name: "John's 401(k)",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    asset_value: Decimal.new("45000.00"),
    book_value: Decimal.new("42000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "John's employer-sponsored 401(k) plan",
    location: "Fidelity",
    custodian: "Fidelity",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "IRA_SARAH_001",
    asset_name: "Sarah's Traditional IRA",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    asset_value: Decimal.new("28000.00"),
    book_value: Decimal.new("25000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Sarah's traditional IRA with Vanguard",
    location: "Vanguard",
    custodian: "Vanguard",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "BROKERAGE_001",
    asset_name: "Joint Investment Account",
    asset_type: "InvestmentSecurities",
    asset_category: "Brokerage",
    asset_value: Decimal.new("35000.00"),
    book_value: Decimal.new("32000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Joint taxable investment account for future goals",
    location: "Schwab",
    custodian: "Charles Schwab",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Medium",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "HOME_001",
    asset_name: "Primary Residence",
    asset_type: "RealEstate",
    asset_category: "Residential",
    asset_value: Decimal.new("380000.00"),
    book_value: Decimal.new("350000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Family home purchased in 2020",
    location: "123 Oak Street, Suburbia, CA",
    custodian: "Self",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "CAR_001",
    asset_name: "Family SUV",
    asset_type: "Vehicles",
    asset_category: "Vehicles",
    asset_value: Decimal.new("28000.00"),
    book_value: Decimal.new("32000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "2021 Honda CR-V for family use",
    location: "Home Garage",
    custodian: "Self",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Medium",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "529_001",
    asset_name: "College Savings 529 Plan",
    asset_type: "InvestmentSecurities",
    asset_category: "Education",
    asset_value: Decimal.new("12000.00"),
    book_value: Decimal.new("10000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "529 plan for future college expenses",
    location: "Vanguard",
    custodian: "Vanguard",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  }
]

young_family_debts = [
  %{
    user_id: user_id,
    debt_identifier: "MORTGAGE_001",
    debt_name: "Home Mortgage",
    debt_type: "Mortgage",
    debt_category: "Residential",
    principal_amount: Decimal.new("350000.00"),
    outstanding_balance: Decimal.new("320000.00"),
    interest_rate: Decimal.new("3.25"),
    currency_code: get_currency.(),
    issue_date: ~D[2020-06-15],
    maturity_date: ~D[2050-06-15],
    next_payment_date: ~D[2025-01-15],
    payment_frequency: get_payment_frequency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "30-year fixed rate mortgage at 3.25%",
    lender: "Wells Fargo",
    is_active: true,
    risk_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    debt_identifier: "AUTO_LOAN_001",
    debt_name: "SUV Auto Loan",
    debt_type: "AutoLoan",
    debt_category: "Personal",
    principal_amount: Decimal.new("32000.00"),
    outstanding_balance: Decimal.new("18000.00"),
    interest_rate: Decimal.new("4.50"),
    currency_code: get_currency.(),
    issue_date: ~D[2021-03-20],
    maturity_date: ~D[2026-03-20],
    next_payment_date: ~D[2025-01-20],
    payment_frequency: get_payment_frequency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "5-year auto loan for Honda CR-V",
    lender: "Honda Financial",
    is_active: true,
    risk_level: "Medium",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    debt_identifier: "CREDIT_CARD_001",
    debt_name: "Chase Credit Card",
    debt_type: "CreditCard",
    debt_category: "Revolving",
    principal_amount: Decimal.new("0.00"),
    outstanding_balance: Decimal.new("1800.00"),
    interest_rate: Decimal.new("18.99"),
    currency_code: get_currency.(),
    issue_date: ~D[2018-01-01],
    maturity_date: nil,
    next_payment_date: ~D[2025-01-25],
    payment_frequency: get_payment_frequency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Chase Freedom Unlimited for daily expenses",
    lender: "Chase Bank",
    is_active: true,
    risk_level: "High",
    validation_status: get_validation_status.()
  }
]

# Cash Flow Seed Data - Comprehensive Monthly Cash Flows

# Young Family (Smith Family) Cash Flows - January 2025
young_family_cash_flows = [
  %{
    user_id: first_user.id,
    cash_flow_identifier: "INCOME_001",
    cash_flow_name: "John's Salary",
    cash_flow_type: "Income",
    cash_flow_category: "Salary",
    cash_flow_subcategory: "Base Salary",
    amount: Decimal.new("7000.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2024-12-31],
    effective_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    frequency: "Monthly",
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-01-31],
    end_date: nil,
    source_account: "Employer Payroll",
    destination_account: "Chase Bank",
    payment_method: "BankTransfer",
    budgeted_amount: Decimal.new("7000.00"),
    budget_period: "Monthly",
    is_budget_item: true,
    budget_category: "Income",
    description: "John's monthly salary",
    notes: nil,
    tags: ["salary", "income"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: "Wages",
    priority_level: "Critical",
    importance_level: "Essential",
    validation_status: get_validation_status.(),
    last_validated_at: DateTime.utc_now()
  },
  %{
    user_id: first_user.id,
    cash_flow_identifier: "SALARY_SARAH_2025_01",
    cash_flow_name: "Sarah's Salary",
    cash_flow_type: "Income",
    cash_flow_category: "Salary",
    cash_flow_subcategory: "Base Salary",
    amount: Decimal.new("5200.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-15],
    effective_date: ~D[2025-01-15],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-15],
    source_account: "Employer",
    destination_account: "CASH_001",
    payment_method: get_payment_method.(),
    budgeted_amount: Decimal.new("5200.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Income",
    description: "Sarah's monthly salary from DesignStudio",
    notes: "Part-time position with flexible hours",
    tags: ["salary", "secondary-income"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: get_tax_category.(),
    priority_level: get_priority_level.(),
    importance_level: "Essential",
    validation_status: get_validation_status.()
  },
  %{
    user_id: first_user.id,
    cash_flow_identifier: "DIVIDEND_INVESTMENT_2025_01",
    cash_flow_name: "Investment Dividends",
    cash_flow_type: "Income",
    cash_flow_category: "Investment",
    cash_flow_subcategory: "Dividend",
    amount: Decimal.new("150.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-31],
    effective_date: ~D[2025-01-31],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: "Quarterly",
    is_recurring: true,
    recurrence_pattern: "Quarterly",
    next_occurrence_date: ~D[2025-04-30],
    source_account: "BROKERAGE_001",
    destination_account: "CASH_001",
    payment_method: "BankTransfer",
    budgeted_amount: Decimal.new("150.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Investment Income",
    description: "Quarterly dividends from investment portfolio",
    notes: "Reinvested automatically",
    tags: ["dividend", "investment-income"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: "OrdinaryIncome",
    priority_level: "Low",
    importance_level: "NiceToHave",
    validation_status: get_validation_status.()
  },

  # Expenses
  %{
    user_id: first_user.id,
    cash_flow_identifier: "MORTGAGE_PAYMENT_2025_01",
    cash_flow_name: "Mortgage Payment",
    cash_flow_type: "Expense",
    cash_flow_category: "Housing",
    cash_flow_subcategory: "Mortgage",
    amount: Decimal.new("2100.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-01],
    effective_date: ~D[2025-01-01],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-01],
    source_account: "CASH_001",
    destination_account: "MORTGAGE_001",
    payment_method: get_payment_method.(),
    budgeted_amount: Decimal.new("2100.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Housing",
    description: "Monthly mortgage payment including principal and interest",
    notes: "Fixed rate 30-year mortgage",
    tags: ["mortgage", "housing"],
    is_active: true,
    is_tax_deductible: true,
    tax_category: "Deductible",
    priority_level: "Critical",
    importance_level: "Essential",
    validation_status: get_validation_status.()
  },
  %{
    user_id: first_user.id,
    cash_flow_identifier: "UTILITIES_2025_01",
    cash_flow_name: "Utilities",
    cash_flow_type: "Expense",
    cash_flow_category: "Utilities",
    cash_flow_subcategory: "Electricity",
    amount: Decimal.new("180.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-15],
    effective_date: ~D[2025-01-15],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-15],
    source_account: "CASH_001",
    destination_account: "Utility Company",
    payment_method: "BankTransfer",
    budgeted_amount: Decimal.new("200.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Utilities",
    description: "Monthly electricity and gas bill",
    notes: "Higher in winter months",
    tags: ["utilities", "electricity", "gas"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: get_tax_category.(),
    priority_level: "High",
    importance_level: "Essential",
    validation_status: get_validation_status.()
  },
  %{
    user_id: first_user.id,
    cash_flow_identifier: "GROCERIES_2025_01",
    cash_flow_name: "Groceries",
    cash_flow_type: "Expense",
    cash_flow_category: "Food",
    cash_flow_subcategory: "Groceries",
    amount: Decimal.new("600.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-31],
    effective_date: ~D[2025-01-31],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-28],
    source_account: "CASH_001",
    destination_account: "Grocery Store",
    payment_method: "CreditCard",
    budgeted_amount: Decimal.new("600.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Food",
    description: "Monthly grocery shopping for family of 4",
    notes: "Includes organic produce and household items",
    tags: ["groceries", "food", "household"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: get_tax_category.(),
    priority_level: "High",
    importance_level: "Essential",
    validation_status: get_validation_status.()
  },
  %{
    user_id: first_user.id,
    cash_flow_identifier: "CAR_INSURANCE_2025_01",
    cash_flow_name: "Car Insurance",
    cash_flow_type: "Expense",
    cash_flow_category: "Insurance",
    cash_flow_subcategory: "Auto Insurance",
    amount: Decimal.new("120.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-01],
    effective_date: ~D[2025-01-01],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-01],
    source_account: "CASH_001",
    destination_account: "Insurance Company",
    payment_method: "BankTransfer",
    budgeted_amount: Decimal.new("120.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Insurance",
    description: "Monthly car insurance premium",
    notes: "Full coverage for family SUV",
    tags: ["insurance", "auto"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: get_tax_category.(),
    priority_level: "High",
    importance_level: "Essential",
    validation_status: get_validation_status.()
  },
  %{
    user_id: first_user.id,
    cash_flow_identifier: "CHILDCARE_2025_01",
    cash_flow_name: "Childcare",
    cash_flow_type: "Expense",
    cash_flow_category: "Childcare",
    cash_flow_subcategory: "Daycare",
    amount: Decimal.new("800.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-31],
    effective_date: ~D[2025-01-31],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-28],
    source_account: "CASH_001",
    destination_account: "Daycare Center",
    payment_method: "BankTransfer",
    budgeted_amount: Decimal.new("800.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Childcare",
    description: "Monthly daycare for two children",
    notes: "Full-time care for ages 2 and 4",
    tags: ["childcare", "daycare"],
    is_active: true,
    is_tax_deductible: true,
    tax_category: "TaxCredit",
    priority_level: "Critical",
    importance_level: "Essential",
    validation_status: get_validation_status.()
  }
]

# Scenario 2: Established Family (Michael & Lisa Johnson)
established_family_assets = [
  %{
    user_id: user_id,
    asset_identifier: "CASH_002",
    asset_name: "Joint Checking Account",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Checking",
    asset_value: Decimal.new("15000.00"),
    book_value: Decimal.new("15000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Primary joint checking account",
    location: "Wells Fargo",
    custodian: "Wells Fargo",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "High",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "SAVINGS_002",
    asset_name: "Emergency Fund",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Savings",
    asset_value: Decimal.new("50000.00"),
    book_value: Decimal.new("50000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "High-yield savings account for emergency fund",
    location: "Marcus by Goldman Sachs",
    custodian: "Marcus by Goldman Sachs",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "High",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "401K_MARK_001",
    asset_name: "Mark's 401(k)",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    asset_value: Decimal.new("180000.00"),
    book_value: Decimal.new("160000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Mark's employer-sponsored 401(k) plan",
    location: "Vanguard",
    custodian: "Vanguard",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "401K_LISA_001",
    asset_name: "Lisa's 401(k)",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    asset_value: Decimal.new("120000.00"),
    book_value: Decimal.new("110000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Lisa's employer-sponsored 401(k) plan",
    location: "Fidelity",
    custodian: "Fidelity",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "IRA_MARK_001",
    asset_name: "Mark's Traditional IRA",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    asset_value: Decimal.new("85000.00"),
    book_value: Decimal.new("75000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Mark's traditional IRA with Schwab",
    location: "Charles Schwab",
    custodian: "Charles Schwab",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "BROKERAGE_002",
    asset_name: "Joint Investment Account",
    asset_type: "InvestmentSecurities",
    asset_category: "Brokerage",
    asset_value: Decimal.new("95000.00"),
    book_value: Decimal.new("85000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Joint taxable investment account",
    location: "Charles Schwab",
    custodian: "Charles Schwab",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Medium",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "HOME_002",
    asset_name: "Primary Residence",
    asset_type: "RealEstate",
    asset_category: "Residential",
    asset_value: Decimal.new("650000.00"),
    book_value: Decimal.new("550000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Family home purchased in 2015",
    location: "456 Maple Avenue, Suburbia, CA",
    custodian: "Self",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "RENTAL_PROPERTY_001",
    asset_name: "Investment Property",
    asset_type: "RealEstate",
    asset_category: "Investment",
    asset_value: Decimal.new("420000.00"),
    book_value: Decimal.new("380000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Rental property purchased in 2018",
    location: "789 Pine Street, Downtown, CA",
    custodian: "Self",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "CAR_002",
    asset_name: "Family Sedan",
    asset_type: "Vehicles",
    asset_category: "Vehicles",
    asset_value: Decimal.new("22000.00"),
    book_value: Decimal.new("25000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "2019 Toyota Camry for family use",
    location: "Home Garage",
    custodian: "Self",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Medium",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "529_002",
    asset_name: "College Savings 529 Plan",
    asset_type: "InvestmentSecurities",
    asset_category: "Education",
    asset_value: Decimal.new("45000.00"),
    book_value: Decimal.new("40000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "529 plan for child's college education",
    location: "Vanguard",
    custodian: "Vanguard",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    asset_identifier: "HSA_001",
    asset_name: "Health Savings Account",
    asset_type: "InvestmentSecurities",
    asset_category: "Healthcare",
    asset_value: Decimal.new("28000.00"),
    book_value: Decimal.new("25000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "HSA for healthcare expenses",
    location: "Fidelity",
    custodian: "Fidelity",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "Medium",
    validation_status: get_validation_status.()
  }
]

established_family_debts = [
  %{
    user_id: user_id,
    debt_identifier: "MORTGAGE_002",
    debt_name: "Primary Residence Mortgage",
    debt_type: "Mortgage",
    debt_category: "Residential",
    principal_amount: Decimal.new("550000.00"),
    outstanding_balance: Decimal.new("420000.00"),
    interest_rate: Decimal.new("3.75"),
    currency_code: get_currency.(),
    issue_date: ~D[2015-08-20],
    maturity_date: ~D[2045-08-20],
    next_payment_date: ~D[2025-01-20],
    payment_frequency: get_payment_frequency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "30-year fixed rate mortgage with good equity",
    lender: "Quicken Loans",
    is_active: true,
    risk_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    debt_identifier: "RENTAL_MORTGAGE_001",
    debt_name: "Rental Property Mortgage",
    debt_type: "Mortgage",
    debt_category: "Investment",
    principal_amount: Decimal.new("380000.00"),
    outstanding_balance: Decimal.new("320000.00"),
    interest_rate: Decimal.new("4.25"),
    currency_code: get_currency.(),
    issue_date: ~D[2018-03-15],
    maturity_date: ~D[2048-03-15],
    next_payment_date: ~D[2025-01-15],
    payment_frequency: get_payment_frequency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Investment property mortgage",
    lender: "Wells Fargo",
    is_active: true,
    risk_level: "Medium",
    validation_status: get_validation_status.()
  },
  %{
    user_id: user_id,
    debt_identifier: "HELOC_001",
    debt_name: "Home Equity Line of Credit",
    debt_type: "LineOfCredit",
    debt_category: "Revolving",
    principal_amount: Decimal.new("100000.00"),
    outstanding_balance: Decimal.new("25000.00"),
    interest_rate: Decimal.new("5.50"),
    currency_code: get_currency.(),
    issue_date: ~D[2022-01-10],
    maturity_date: ~D[2032-01-10],
    next_payment_date: ~D[2025-01-10],
    payment_frequency: get_payment_frequency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "HELOC for home improvements and emergencies",
    lender: "Bank of America",
    is_active: true,
    risk_level: "Medium",
    validation_status: get_validation_status.()
  }
]

# Established Family (Johnson Family) Cash Flows - January 2025
established_family_cash_flows = [
  %{
    user_id: second_user.id,
    cash_flow_identifier: "INCOME_002",
    cash_flow_name: "Michael's Salary",
    cash_flow_type: "Income",
    cash_flow_category: "Salary",
    cash_flow_subcategory: "Base Salary",
    amount: Decimal.new("12000.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2024-12-31],
    effective_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    frequency: "Monthly",
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-01-31],
    end_date: nil,
    source_account: "Employer Payroll",
    destination_account: "Wells Fargo Bank",
    payment_method: "BankTransfer",
    budgeted_amount: Decimal.new("12000.00"),
    budget_period: "Monthly",
    is_budget_item: true,
    budget_category: "Income",
    description: "Michael's monthly salary",
    notes: nil,
    tags: ["salary", "income"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: "Wages",
    priority_level: "Critical",
    importance_level: "Essential",
    validation_status: get_validation_status.(),
    last_validated_at: DateTime.utc_now()
  },
  %{
    user_id: second_user.id,
    cash_flow_identifier: "RENTAL_INCOME_2025_01",
    cash_flow_name: "Rental Income",
    cash_flow_type: "Income",
    cash_flow_category: "Rental",
    cash_flow_subcategory: "Property Rental",
    amount: Decimal.new("2200.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-01],
    effective_date: ~D[2025-01-01],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-01],
    source_account: "RENTAL_PROPERTY_001",
    destination_account: "CASH_001",
    payment_method: "BankTransfer",
    budgeted_amount: Decimal.new("2200.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Rental Income",
    description: "Monthly rental income from investment property",
    notes: "Long-term tenant, 12-month lease",
    tags: ["rental", "investment-income"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: "OrdinaryIncome",
    priority_level: "Medium",
    importance_level: "Important",
    validation_status: get_validation_status.()
  },

  # Expenses
  %{
    user_id: second_user.id,
    cash_flow_identifier: "MORTGAGE_PAYMENT_JOHNSON_2025_01",
    cash_flow_name: "Primary Home Mortgage",
    cash_flow_type: "Expense",
    cash_flow_category: "Housing",
    cash_flow_subcategory: "Mortgage",
    amount: Decimal.new("2800.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-01],
    effective_date: ~D[2025-01-01],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-01],
    source_account: "CASH_001",
    destination_account: "MORTGAGE_001",
    payment_method: get_payment_method.(),
    budgeted_amount: Decimal.new("2800.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Housing",
    description: "Monthly mortgage payment for primary residence",
    notes: "15-year fixed rate mortgage",
    tags: ["mortgage", "housing"],
    is_active: true,
    is_tax_deductible: true,
    tax_category: "Deductible",
    priority_level: "Critical",
    importance_level: "Essential",
    validation_status: get_validation_status.()
  },
  %{
    user_id: second_user.id,
    cash_flow_identifier: "PRIVATE_SCHOOL_2025_01",
    cash_flow_name: "Private School Tuition",
    cash_flow_type: "Expense",
    cash_flow_category: "Education",
    cash_flow_subcategory: "Tuition",
    amount: Decimal.new("1200.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-15],
    effective_date: ~D[2025-01-15],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-15],
    source_account: "CASH_001",
    destination_account: "Private School",
    payment_method: "BankTransfer",
    budgeted_amount: Decimal.new("1200.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Education",
    description: "Monthly tuition for private school",
    notes: "For one child, grades 6-8",
    tags: ["education", "tuition", "private-school"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: get_tax_category.(),
    priority_level: "High",
    importance_level: "Important",
    validation_status: get_validation_status.()
  },
  %{
    user_id: second_user.id,
    cash_flow_identifier: "HEALTH_INSURANCE_2025_01",
    cash_flow_name: "Health Insurance Premium",
    cash_flow_type: "Expense",
    cash_flow_category: "Healthcare",
    cash_flow_subcategory: "Insurance Premium",
    amount: Decimal.new("450.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-01],
    effective_date: ~D[2025-01-01],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-01],
    source_account: "CASH_001",
    destination_account: "Insurance Company",
    payment_method: "BankTransfer",
    budgeted_amount: Decimal.new("450.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Healthcare",
    description: "Monthly health insurance premium for family",
    notes: "Comprehensive coverage with dental and vision",
    tags: ["healthcare", "insurance"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: get_tax_category.(),
    priority_level: "Critical",
    importance_level: "Essential",
    validation_status: get_validation_status.()
  },
  %{
    user_id: second_user.id,
    cash_flow_identifier: "INVESTMENT_CONTRIBUTION_2025_01",
    cash_flow_name: "Investment Contribution",
    cash_flow_type: "Expense",
    cash_flow_category: "Savings",
    cash_flow_subcategory: "Investment",
    amount: Decimal.new("1000.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-31],
    effective_date: ~D[2025-01-31],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-28],
    source_account: "CASH_001",
    destination_account: "BROKERAGE_001",
    payment_method: "BankTransfer",
    budgeted_amount: Decimal.new("1000.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Savings",
    description: "Monthly investment contribution to brokerage account",
    notes: "Automated investment for retirement planning",
    tags: ["investment", "savings", "retirement"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: get_tax_category.(),
    priority_level: "Medium",
    importance_level: "Important",
    validation_status: get_validation_status.()
  }
]

# Scenario 3: Single Professional (Alex Chen)
single_professional_assets = [
  %{
    user_id: third_user.id,
    asset_identifier: "CASH_003",
    asset_name: "Checking Account",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Checking",
    fair_value: Decimal.new("12000.00"),
    book_value: Decimal.new("12000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Primary checking account for daily expenses",
    location: "Ally Bank",
    custodian: "Ally Bank",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "High",
    validation_status: get_validation_status.(),
    last_validated_at: DateTime.utc_now()
  },
  %{
    user_id: third_user.id,
    asset_identifier: "SAVINGS_003",
    asset_name: "Emergency Fund",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Savings",
    asset_value: Decimal.new("15000.00"),
    book_value: Decimal.new("15000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "High-yield savings account for emergency fund",
    location: "Ally Bank",
    custodian: "Ally Bank",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "High",
    validation_status: get_validation_status.()
  },
  %{
    user_id: third_user.id,
    asset_identifier: "401K_ALEX_001",
    asset_name: "Alex's 401(k)",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    asset_value: Decimal.new("75000.00"),
    book_value: Decimal.new("65000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Alex's employer-sponsored 401(k) plan",
    location: "Fidelity",
    custodian: "Fidelity",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: third_user.id,
    asset_identifier: "IRA_ALEX_001",
    asset_name: "Alex's Roth IRA",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    asset_value: Decimal.new("35000.00"),
    book_value: Decimal.new("30000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Alex's Roth IRA with Vanguard",
    location: "Vanguard",
    custodian: "Vanguard",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: third_user.id,
    asset_identifier: "BROKERAGE_003",
    asset_name: "Individual Investment Account",
    asset_type: "InvestmentSecurities",
    asset_category: "Brokerage",
    asset_value: Decimal.new("45000.00"),
    book_value: Decimal.new("40000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Individual taxable investment account",
    location: "Robinhood",
    custodian: "Robinhood",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Medium",
    validation_status: get_validation_status.()
  },
  %{
    user_id: third_user.id,
    asset_identifier: "CONDO_001",
    asset_name: "Downtown Condo",
    asset_type: "RealEstate",
    asset_category: "Residential",
    asset_value: Decimal.new("280000.00"),
    book_value: Decimal.new("250000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Downtown condo purchased in 2021",
    location: "123 Urban Street, Downtown, CA",
    custodian: "Self",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: third_user.id,
    asset_identifier: "CAR_003",
    asset_name: "Tesla Model 3",
    asset_type: "Vehicles",
    asset_category: "Vehicles",
    asset_value: Decimal.new("35000.00"),
    book_value: Decimal.new("40000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Electric vehicle for commuting",
    location: "Condo Garage",
    custodian: "Self",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Medium",
    validation_status: get_validation_status.()
  }
]

single_professional_debts = [
  %{
    user_id: third_user.id,
    debt_identifier: "CONDO_MORTGAGE_001",
    debt_name: "Condo Mortgage",
    debt_type: "Mortgage",
    debt_category: "Residential",
    principal_amount: Decimal.new("250000.00"),
    outstanding_balance: Decimal.new("220000.00"),
    interest_rate: Decimal.new("3.50"),
    currency_code: get_currency.(),
    issue_date: ~D[2021-06-01],
    maturity_date: ~D[2051-06-01],
    next_payment_date: ~D[2025-01-01],
    payment_frequency: get_payment_frequency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "30-year fixed rate condo mortgage",
    lender: "Quicken Loans",
    is_active: true,
    risk_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    user_id: third_user.id,
    debt_identifier: "STUDENT_LOAN_003",
    debt_name: "Student Loan",
    debt_type: "StudentLoan",
    debt_category: "Federal",
    principal_amount: Decimal.new("40000.00"),
    outstanding_balance: Decimal.new("25000.00"),
    interest_rate: Decimal.new("4.5"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "Federal student loan for graduate school",
    lender: "FedLoan Servicing",
    is_active: true,
    risk_level: "Medium",
    validation_status: get_validation_status.(),
    last_validated_at: DateTime.utc_now()
  },
  %{
    user_id: third_user.id,
    debt_identifier: "CREDIT_CARD_002",
    debt_name: "Amex Credit Card",
    debt_type: "CreditCard",
    debt_category: "Revolving",
    principal_amount: Decimal.new("0.00"),
    outstanding_balance: Decimal.new("1200.00"),
    interest_rate: Decimal.new("16.99"),
    currency_code: get_currency.(),
    issue_date: ~D[2019-01-01],
    maturity_date: nil,
    next_payment_date: ~D[2025-01-20],
    payment_frequency: get_payment_frequency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    description: "American Express card for travel rewards",
    lender: "American Express",
    is_active: true,
    risk_level: "High",
    validation_status: get_validation_status.()
  }
]

# Single Professional (Alex Chen) Cash Flows - January 2025
single_professional_cash_flows = [
  %{
    user_id: third_user.id,
    cash_flow_identifier: "INCOME_003",
    cash_flow_name: "Carol's Salary",
    cash_flow_type: "Income",
    cash_flow_category: "Salary",
    cash_flow_subcategory: "Base Salary",
    amount: Decimal.new("9000.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2024-12-31],
    effective_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_scenario: get_scenario_type.(),
    frequency: "Monthly",
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-01-31],
    end_date: nil,
    source_account: "Employer Payroll",
    destination_account: "Ally Bank",
    payment_method: "BankTransfer",
    budgeted_amount: Decimal.new("9000.00"),
    budget_period: "Monthly",
    is_budget_item: true,
    budget_category: "Income",
    description: "Carol's monthly salary",
    notes: nil,
    tags: ["salary", "income"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: "Wages",
    priority_level: "Critical",
    importance_level: "Essential",
    validation_status: get_validation_status.(),
    last_validated_at: DateTime.utc_now()
  },
  %{
    user_id: third_user.id,
    cash_flow_identifier: "FREELANCE_INCOME_2025_01",
    cash_flow_name: "Freelance Income",
    cash_flow_type: "Income",
    cash_flow_category: "Business",
    cash_flow_subcategory: "Freelance",
    amount: Decimal.new("1200.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-31],
    effective_date: ~D[2025-01-31],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-28],
    source_account: "Freelance Clients",
    destination_account: "CASH_001",
    payment_method: "BankTransfer",
    budgeted_amount: Decimal.new("1000.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Business Income",
    description: "Monthly freelance web development income",
    notes: "Side projects and consulting work",
    tags: ["freelance", "business", "side-income"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: "OrdinaryIncome",
    priority_level: "Medium",
    importance_level: "Important",
    validation_status: get_validation_status.()
  },
  %{
    user_id: third_user.id,
    cash_flow_identifier: "CONDO_MORTGAGE_2025_01",
    cash_flow_name: "Condo Mortgage Payment",
    cash_flow_type: "Expense",
    cash_flow_category: "Housing",
    cash_flow_subcategory: "Mortgage",
    amount: Decimal.new("1800.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-01],
    effective_date: ~D[2025-01-01],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-01],
    source_account: "CASH_001",
    destination_account: "CONDO_MORTGAGE_001",
    payment_method: get_payment_method.(),
    budgeted_amount: Decimal.new("1800.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Housing",
    description: "Monthly condo mortgage payment",
    notes: "30-year fixed rate mortgage",
    tags: ["mortgage", "housing", "condo"],
    is_active: true,
    is_tax_deductible: true,
    tax_category: "Deductible",
    priority_level: "Critical",
    importance_level: "Essential",
    validation_status: get_validation_status.()
  },
  %{
    user_id: third_user.id,
    cash_flow_identifier: "STUDENT_LOAN_PAYMENT_2025_01",
    cash_flow_name: "Student Loan Payment",
    cash_flow_type: "Expense",
    cash_flow_category: "Debt",
    cash_flow_subcategory: "Student Loan",
    amount: Decimal.new("350.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-15],
    effective_date: ~D[2025-01-15],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-15],
    source_account: "CASH_001",
    destination_account: "STUDENT_LOAN_003",
    payment_method: "BankTransfer",
    budgeted_amount: Decimal.new("350.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Debt",
    description: "Monthly student loan payment",
    notes: "Federal student loan for graduate degree",
    tags: ["student-loan", "debt"],
    is_active: true,
    is_tax_deductible: true,
    tax_category: "Deductible",
    priority_level: "High",
    importance_level: "Important",
    validation_status: get_validation_status.()
  },
  %{
    user_id: third_user.id,
    cash_flow_identifier: "GROCERIES_ALEX_2025_01",
    cash_flow_name: "Groceries",
    cash_flow_type: "Expense",
    cash_flow_category: "Food",
    cash_flow_subcategory: "Groceries",
    amount: Decimal.new("300.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-31],
    effective_date: ~D[2025-01-31],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-28],
    source_account: "CASH_001",
    destination_account: "Grocery Store",
    payment_method: "CreditCard",
    budgeted_amount: Decimal.new("300.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Food",
    description: "Monthly grocery shopping for single person",
    notes: "Includes meal prep ingredients and snacks",
    tags: ["groceries", "food"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: "NonDeductible",
    priority_level: "High",
    importance_level: "Essential",
    validation_status: get_validation_status.()
  },
  %{
    user_id: third_user.id,
    cash_flow_identifier: "ENTERTAINMENT_2025_01",
    cash_flow_name: "Entertainment",
    cash_flow_type: "Expense",
    cash_flow_category: "Entertainment",
    cash_flow_subcategory: "Dining Out",
    amount: Decimal.new("400.00"),
    currency_code: get_currency.(),
    transaction_date: ~D[2025-01-31],
    effective_date: ~D[2025-01-31],
    reporting_period: "2025-01",
    reporting_scenario: get_scenario_type.(),
    frequency: get_cash_flow_frequency.(),
    is_recurring: true,
    recurrence_pattern: "Monthly",
    next_occurrence_date: ~D[2025-02-28],
    source_account: "CASH_001",
    destination_account: "Restaurants",
    payment_method: "CreditCard",
    budgeted_amount: Decimal.new("400.00"),
    budget_period: get_budget_period.(),
    is_budget_item: true,
    budget_category: "Entertainment",
    description: "Monthly dining out and entertainment expenses",
    notes: "Restaurants, movies, and social activities",
    tags: ["entertainment", "dining", "social"],
    is_active: true,
    is_tax_deductible: false,
    tax_category: "NonDeductible",
    priority_level: "Low",
    importance_level: "NiceToHave",
    validation_status: get_validation_status.()
  }
]

# Insert all seed data
IO.puts("Creating comprehensive family financial scenarios...")

# Insert Young Family Data
Enum.each(young_family_assets, fn asset_attrs ->
  case FinancialInstruments.create_asset(asset_attrs) do
    {:ok, asset} ->
      IO.puts("Created young family asset: #{asset.asset_name}")
    {:error, changeset} ->
      IO.puts("Failed to create young family asset: #{inspect(changeset.errors)}")
  end
end)

Enum.each(young_family_debts, fn debt_attrs ->
  case FinancialInstruments.create_debt_obligation(debt_attrs) do
    {:ok, debt} ->
      IO.puts("Created young family debt: #{debt.debt_name}")
    {:error, changeset} ->
      IO.puts("Failed to create young family debt: #{inspect(changeset.errors)}")
  end
end)

# Insert Established Family Data
Enum.each(established_family_assets, fn asset_attrs ->
  case FinancialInstruments.create_asset(asset_attrs) do
    {:ok, asset} ->
      IO.puts("Created established family asset: #{asset.asset_name}")
    {:error, changeset} ->
      IO.puts("Failed to create established family asset: #{inspect(changeset.errors)}")
  end
end)

Enum.each(established_family_debts, fn debt_attrs ->
  case FinancialInstruments.create_debt_obligation(debt_attrs) do
    {:ok, debt} ->
      IO.puts("Created established family debt: #{debt.debt_name}")
    {:error, changeset} ->
      IO.puts("Failed to create established family debt: #{inspect(changeset.errors)}")
  end
end)

# Insert Single Professional Data
Enum.each(single_professional_assets, fn asset_attrs ->
  case FinancialInstruments.create_asset(asset_attrs) do
    {:ok, asset} ->
      IO.puts("Created single professional asset: #{asset.asset_name}")
    {:error, changeset} ->
      IO.puts("Failed to create single professional asset: #{inspect(changeset.errors)}")
  end
end)

Enum.each(single_professional_debts, fn debt_attrs ->
  case FinancialInstruments.create_debt_obligation(debt_attrs) do
    {:ok, debt} ->
      IO.puts("Created single professional debt: #{debt.debt_name}")
    {:error, changeset} ->
      IO.puts("Failed to create single professional debt: #{inspect(changeset.errors)}")
  end
end)

# Insert Cash Flow Data
Enum.each(young_family_cash_flows, fn cash_flow_attrs ->
  case FinancialInstruments.create_cash_flow(cash_flow_attrs) do
    {:ok, cash_flow} ->
      IO.puts("Created young family cash flow: #{cash_flow.cash_flow_name}")
    {:error, changeset} ->
      IO.puts("Failed to create young family cash flow: #{inspect(changeset.errors)}")
  end
end)

Enum.each(established_family_cash_flows, fn cash_flow_attrs ->
  case FinancialInstruments.create_cash_flow(cash_flow_attrs) do
    {:ok, cash_flow} ->
      IO.puts("Created established family cash flow: #{cash_flow.cash_flow_name}")
    {:error, changeset} ->
      IO.puts("Failed to create established family cash flow: #{inspect(changeset.errors)}")
  end
end)

Enum.each(single_professional_cash_flows, fn cash_flow_attrs ->
  case FinancialInstruments.create_cash_flow(cash_flow_attrs) do
    {:ok, cash_flow} ->
      IO.puts("Created single professional cash flow: #{cash_flow.cash_flow_name}")
    {:error, changeset} ->
      IO.puts("Failed to create single professional cash flow: #{inspect(changeset.errors)}")
  end
end)

IO.puts("\n=== Financial Scenarios Created ===")
IO.puts("1. Young Family (Smith Family) - 8 assets, 3 debts, 7 cash flows")
IO.puts("2. Established Family (Johnson Family) - 11 assets, 3 debts, 6 cash flows")
IO.puts("3. Single Professional (Alex Chen) - 7 assets, 3 debts, 5 cash flows")
IO.puts("\nTotal: 26 assets, 9 debt obligations, 18 cash flows")

# Generate sample reports for each user
IO.puts("\n=== Sample Financial Reports ===")

[{first_user, "SMITH_FAMILY_001"}, {second_user, "JOHNSON_FAMILY_001"}, {third_user, "CHEN_INDIVIDUAL_001"}]
|> Enum.each(fn {user, entity_label} ->
  IO.puts("\n--- #{entity_label} Financial Summary ---")

  assets = FinancialInstruments.list_assets_by_user(user.id)
  debts = FinancialInstruments.list_debt_obligations_by_user(user.id)
  cash_flows = FinancialInstruments.list_cash_flows_by_user_and_period(user.id, "2025-01")

  total_assets = Enum.reduce(assets, Decimal.new("0"), fn asset, acc ->
    Decimal.add(acc, asset.fair_value || Decimal.new("0"))
  end)

  total_debts = Enum.reduce(debts, Decimal.new("0"), fn debt, acc ->
    Decimal.add(acc, debt.outstanding_balance || Decimal.new("0"))
  end)

  net_worth = Decimal.sub(total_assets, total_debts)

  # Calculate cash flow summary
  income_cash_flows = Enum.filter(cash_flows, &(&1.cash_flow_type == "Income"))
  expense_cash_flows = Enum.filter(cash_flows, &(&1.cash_flow_type == "Expense"))

  total_income = Enum.reduce(income_cash_flows, Decimal.new("0"), fn cf, acc ->
    Decimal.add(acc, cf.amount || Decimal.new("0"))
  end)

  total_expenses = Enum.reduce(expense_cash_flows, Decimal.new("0"), fn cf, acc ->
    Decimal.add(acc, cf.amount || Decimal.new("0"))
  end)

  net_cash_flow = Decimal.sub(total_income, total_expenses)

  IO.puts("Total Assets: $#{Decimal.to_string(total_assets)}")
  IO.puts("Total Debts: $#{Decimal.to_string(total_debts)}")
  IO.puts("Net Worth: $#{Decimal.to_string(net_worth)}")
  IO.puts("Monthly Income: $#{Decimal.to_string(total_income)}")
  IO.puts("Monthly Expenses: $#{Decimal.to_string(total_expenses)}")
  IO.puts("Net Cash Flow: $#{Decimal.to_string(net_cash_flow)}")
end)

IO.puts("\nSeed data creation completed successfully!")
