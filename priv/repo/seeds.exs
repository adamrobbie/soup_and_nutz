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
alias SoupAndNutz.FinancialInstruments.{Asset, DebtObligation}
alias SoupAndNutz.XBRL.Concepts

# Clear existing data
IO.puts("Clearing existing data...")
SoupAndNutz.Repo.delete_all(Asset)
SoupAndNutz.Repo.delete_all(DebtObligation)

# Helper functions using XBRL concepts
get_currency = fn -> List.first(Concepts.currency_codes()) end
get_payment_frequency = fn -> "Monthly" end
get_validation_status = fn -> "Pending" end
get_scenario_type = fn -> List.first(Concepts.scenario_types()) end

# Family Financial Scenarios - Comprehensive Seed Data

# Scenario 1: Young Family (John & Sarah Smith)
young_family_assets = [
  %{
    asset_identifier: "CASH_001",
    asset_name: "Joint Checking Account",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Checking",
    fair_value: Decimal.new("8500.00"),
    book_value: Decimal.new("8500.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "SMITH_FAMILY_001",
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
    asset_identifier: "SAVINGS_001",
    asset_name: "Emergency Fund",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Savings",
    fair_value: Decimal.new("25000.00"),
    book_value: Decimal.new("25000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "SMITH_FAMILY_001",
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
    asset_identifier: "401K_JOHN_001",
    asset_name: "John's 401(k)",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    fair_value: Decimal.new("45000.00"),
    book_value: Decimal.new("42000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "SMITH_FAMILY_001",
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
    asset_identifier: "IRA_SARAH_001",
    asset_name: "Sarah's Traditional IRA",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    fair_value: Decimal.new("28000.00"),
    book_value: Decimal.new("25000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "SMITH_FAMILY_001",
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
    asset_identifier: "BROKERAGE_001",
    asset_name: "Joint Investment Account",
    asset_type: "InvestmentSecurities",
    asset_category: "Brokerage",
    fair_value: Decimal.new("35000.00"),
    book_value: Decimal.new("32000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "SMITH_FAMILY_001",
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
    asset_identifier: "HOME_001",
    asset_name: "Primary Residence",
    asset_type: "RealEstate",
    asset_category: "Residential",
    fair_value: Decimal.new("380000.00"),
    book_value: Decimal.new("350000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "SMITH_FAMILY_001",
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
    asset_identifier: "CAR_001",
    asset_name: "Family SUV",
    asset_type: "Vehicles",
    asset_category: "Vehicles",
    fair_value: Decimal.new("28000.00"),
    book_value: Decimal.new("32000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "SMITH_FAMILY_001",
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
    asset_identifier: "529_001",
    asset_name: "College Savings 529 Plan",
    asset_type: "InvestmentSecurities",
    asset_category: "Education",
    fair_value: Decimal.new("12000.00"),
    book_value: Decimal.new("10000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "SMITH_FAMILY_001",
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
    reporting_entity: "SMITH_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "30-year fixed rate mortgage at 3.25%",
    lender: "Wells Fargo",
    is_active: true,
    risk_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
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
    reporting_entity: "SMITH_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "5-year auto loan for Honda CR-V",
    lender: "Honda Financial",
    is_active: true,
    risk_level: "Medium",
    validation_status: get_validation_status.()
  },
  %{
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
    reporting_entity: "SMITH_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "Chase Freedom Unlimited for daily expenses",
    lender: "Chase Bank",
    is_active: true,
    risk_level: "High",
    validation_status: get_validation_status.()
  }
]

# Scenario 2: Established Family (Michael & Lisa Johnson)
established_family_assets = [
  %{
    asset_identifier: "CASH_002",
    asset_name: "Joint Checking Account",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Checking",
    fair_value: Decimal.new("15000.00"),
    book_value: Decimal.new("15000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "JOHNSON_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "Primary joint checking account",
    location: "Bank of America",
    custodian: "Bank of America",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "High",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "SAVINGS_002",
    asset_name: "Emergency Fund",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Savings",
    fair_value: Decimal.new("50000.00"),
    book_value: Decimal.new("50000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "JOHNSON_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "High-yield savings for emergencies",
    location: "Marcus by Goldman Sachs",
    custodian: "Marcus by Goldman Sachs",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "High",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "401K_MICHAEL_001",
    asset_name: "Michael's 401(k)",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    fair_value: Decimal.new("180000.00"),
    book_value: Decimal.new("160000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "JOHNSON_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "Michael's employer 401(k) with 15 years of contributions",
    location: "T. Rowe Price",
    custodian: "T. Rowe Price",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "401K_LISA_001",
    asset_name: "Lisa's 401(k)",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    fair_value: Decimal.new("120000.00"),
    book_value: Decimal.new("110000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "JOHNSON_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "Lisa's employer 401(k) plan",
    location: "Vanguard",
    custodian: "Vanguard",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "IRA_MICHAEL_001",
    asset_name: "Michael's Roth IRA",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    fair_value: Decimal.new("85000.00"),
    book_value: Decimal.new("75000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "JOHNSON_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "Michael's Roth IRA for tax-free retirement income",
    location: "Fidelity",
    custodian: "Fidelity",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "BROKERAGE_002",
    asset_name: "Joint Investment Portfolio",
    asset_type: "InvestmentSecurities",
    asset_category: "Brokerage",
    fair_value: Decimal.new("95000.00"),
    book_value: Decimal.new("85000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "JOHNSON_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "Diversified investment portfolio for wealth building",
    location: "Schwab",
    custodian: "Charles Schwab",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Medium",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "HOME_002",
    asset_name: "Primary Residence",
    asset_type: "RealEstate",
    asset_category: "Residential",
    fair_value: Decimal.new("650000.00"),
    book_value: Decimal.new("550000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "JOHNSON_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "Family home with significant equity",
    location: "456 Pine Avenue, Suburbia, CA",
    custodian: "Self",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "RENTAL_001",
    asset_name: "Rental Property",
    asset_type: "RealEstate",
    asset_category: "Investment",
    fair_value: Decimal.new("420000.00"),
    book_value: Decimal.new("380000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "JOHNSON_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "Rental property generating monthly income",
    location: "789 Oak Drive, Rental City, CA",
    custodian: "Self",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "CAR_002",
    asset_name: "Family Sedan",
    asset_type: "Vehicles",
    asset_category: "Vehicles",
    fair_value: Decimal.new("22000.00"),
    book_value: Decimal.new("25000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "JOHNSON_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "2019 Toyota Camry for daily commuting",
    location: "Home Garage",
    custodian: "Self",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Medium",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "529_002",
    asset_name: "College Fund 529",
    asset_type: "InvestmentSecurities",
    asset_category: "Education",
    fair_value: Decimal.new("45000.00"),
    book_value: Decimal.new("40000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "JOHNSON_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "529 plan for children's college education",
    location: "Vanguard",
    custodian: "Vanguard",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "HSA_001",
    asset_name: "Health Savings Account",
    asset_type: "InvestmentSecurities",
    asset_category: "Healthcare",
    fair_value: Decimal.new("28000.00"),
    book_value: Decimal.new("25000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "JOHNSON_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "HSA for healthcare expenses and retirement",
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
    reporting_entity: "JOHNSON_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "30-year fixed rate mortgage with good equity",
    lender: "Quicken Loans",
    is_active: true,
    risk_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
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
    reporting_entity: "JOHNSON_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "Investment property mortgage",
    lender: "Wells Fargo",
    is_active: true,
    risk_level: "Medium",
    validation_status: get_validation_status.()
  },
  %{
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
    reporting_entity: "JOHNSON_FAMILY_001",
    reporting_scenario: get_scenario_type.(),
    description: "HELOC for home improvements and emergencies",
    lender: "Bank of America",
    is_active: true,
    risk_level: "Medium",
    validation_status: get_validation_status.()
  }
]

# Scenario 3: Single Professional (Alex Chen)
single_professional_assets = [
  %{
    asset_identifier: "CASH_003",
    asset_name: "Primary Checking",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Checking",
    fair_value: Decimal.new("8000.00"),
    book_value: Decimal.new("8000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "CHEN_INDIVIDUAL_001",
    reporting_scenario: get_scenario_type.(),
    description: "Main checking account for expenses",
    location: "Chase Bank",
    custodian: "Chase Bank",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "High",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "SAVINGS_003",
    asset_name: "Emergency Fund",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Savings",
    fair_value: Decimal.new("15000.00"),
    book_value: Decimal.new("15000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "CHEN_INDIVIDUAL_001",
    reporting_scenario: get_scenario_type.(),
    description: "Emergency savings fund",
    location: "Ally Bank",
    custodian: "Ally Bank",
    is_active: true,
    risk_level: "Low",
    liquidity_level: "High",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "401K_ALEX_001",
    asset_name: "401(k) Retirement Plan",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    fair_value: Decimal.new("75000.00"),
    book_value: Decimal.new("65000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "CHEN_INDIVIDUAL_001",
    reporting_scenario: get_scenario_type.(),
    description: "Employer-sponsored 401(k) plan",
    location: "Vanguard",
    custodian: "Vanguard",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "ROTH_IRA_001",
    asset_name: "Roth IRA",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    fair_value: Decimal.new("35000.00"),
    book_value: Decimal.new("30000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "CHEN_INDIVIDUAL_001",
    reporting_scenario: get_scenario_type.(),
    description: "Roth IRA for tax-free retirement income",
    location: "Fidelity",
    custodian: "Fidelity",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "BROKERAGE_003",
    asset_name: "Individual Investment Account",
    asset_type: "InvestmentSecurities",
    asset_category: "Brokerage",
    fair_value: Decimal.new("45000.00"),
    book_value: Decimal.new("40000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "CHEN_INDIVIDUAL_001",
    reporting_scenario: get_scenario_type.(),
    description: "Taxable investment account for wealth building",
    location: "Schwab",
    custodian: "Charles Schwab",
    is_active: true,
    risk_level: "Medium",
    liquidity_level: "Medium",
    validation_status: get_validation_status.()
  },
  %{
    asset_identifier: "CONDO_001",
    asset_name: "Condo",
    asset_type: "RealEstate",
    asset_category: "Residential",
    fair_value: Decimal.new("280000.00"),
    book_value: Decimal.new("250000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "CHEN_INDIVIDUAL_001",
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
    asset_identifier: "CAR_003",
    asset_name: "Tesla Model 3",
    asset_type: "Vehicles",
    asset_category: "Vehicles",
    fair_value: Decimal.new("35000.00"),
    book_value: Decimal.new("40000.00"),
    currency_code: get_currency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "CHEN_INDIVIDUAL_001",
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
    reporting_entity: "CHEN_INDIVIDUAL_001",
    reporting_scenario: get_scenario_type.(),
    description: "30-year fixed rate condo mortgage",
    lender: "Quicken Loans",
    is_active: true,
    risk_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
    debt_identifier: "STUDENT_LOAN_001",
    debt_name: "Student Loan",
    debt_type: "StudentLoan",
    debt_category: "Education",
    principal_amount: Decimal.new("45000.00"),
    outstanding_balance: Decimal.new("28000.00"),
    interest_rate: Decimal.new("4.25"),
    currency_code: get_currency.(),
    issue_date: ~D[2018-09-01],
    maturity_date: ~D[2033-09-01],
    next_payment_date: ~D[2025-01-15],
    payment_frequency: get_payment_frequency.(),
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "CHEN_INDIVIDUAL_001",
    reporting_scenario: get_scenario_type.(),
    description: "Federal student loan for graduate degree",
    lender: "Department of Education",
    is_active: true,
    risk_level: "Low",
    validation_status: get_validation_status.()
  },
  %{
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
    reporting_entity: "CHEN_INDIVIDUAL_001",
    reporting_scenario: get_scenario_type.(),
    description: "American Express card for travel rewards",
    lender: "American Express",
    is_active: true,
    risk_level: "High",
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

IO.puts("\n=== Financial Scenarios Created ===")
IO.puts("1. Young Family (Smith Family) - 8 assets, 3 debts")
IO.puts("2. Established Family (Johnson Family) - 11 assets, 3 debts")
IO.puts("3. Single Professional (Alex Chen) - 7 assets, 3 debts")
IO.puts("\nTotal: 26 assets, 9 debt obligations")

# Generate sample reports for each entity
IO.puts("\n=== Sample Financial Reports ===")

["SMITH_FAMILY_001", "JOHNSON_FAMILY_001", "CHEN_INDIVIDUAL_001"]
|> Enum.each(fn entity ->
  IO.puts("\n--- #{entity} Financial Summary ---")

  assets = FinancialInstruments.list_assets_by_entity(entity)
  debts = FinancialInstruments.list_debt_obligations_by_entity(entity)

  total_assets = Enum.reduce(assets, Decimal.new("0"), fn asset, acc ->
    Decimal.add(acc, asset.fair_value)
  end)

  total_debts = Enum.reduce(debts, Decimal.new("0"), fn debt, acc ->
    Decimal.add(acc, debt.outstanding_balance)
  end)

  net_worth = Decimal.sub(total_assets, total_debts)

  IO.puts("Total Assets: $#{Decimal.to_string(total_assets)}")
  IO.puts("Total Debts: $#{Decimal.to_string(total_debts)}")
  IO.puts("Net Worth: $#{Decimal.to_string(net_worth)}")
end)

IO.puts("\nSeed data creation completed successfully!")
