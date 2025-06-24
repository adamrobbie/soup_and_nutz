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

# Sample Assets
sample_assets = [
  %{
    asset_identifier: "CASH_001",
    asset_name: "Primary Checking Account",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Checking",
    fair_value: Decimal.new("15000.00"),
    book_value: Decimal.new("15000.00"),
    currency_code: "USD",
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "INDIVIDUAL_001",
    reporting_scenario: "Actual",
    description: "Main checking account at Bank of America",
    location: "Bank of America",
    custodian: "Bank of America",
    risk_level: "Low",
    liquidity_level: "High"
  },
  %{
    asset_identifier: "INVEST_001",
    asset_name: "Vanguard 401(k)",
    asset_type: "InvestmentSecurities",
    asset_category: "Retirement",
    fair_value: Decimal.new("125000.00"),
    book_value: Decimal.new("120000.00"),
    currency_code: "USD",
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "INDIVIDUAL_001",
    reporting_scenario: "Actual",
    description: "Employer-sponsored 401(k) retirement plan",
    location: "Vanguard",
    custodian: "Vanguard",
    risk_level: "Medium",
    liquidity_level: "Medium"
  },
  %{
    asset_identifier: "REAL_ESTATE_001",
    asset_name: "Primary Residence",
    asset_type: "RealEstate",
    asset_category: "Residential",
    fair_value: Decimal.new("450000.00"),
    book_value: Decimal.new("400000.00"),
    currency_code: "USD",
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "INDIVIDUAL_001",
    reporting_scenario: "Actual",
    description: "Family home in suburban area",
    location: "123 Main St, Anytown, USA",
    custodian: "Self",
    risk_level: "Low",
    liquidity_level: "Low"
  }
]

# Sample Debt Obligations
sample_debts = [
  %{
    debt_identifier: "MORTGAGE_001",
    debt_name: "Primary Residence Mortgage",
    debt_type: "Mortgage",
    debt_category: "Residential",
    principal_amount: Decimal.new("350000.00"),
    outstanding_balance: Decimal.new("320000.00"),
    interest_rate: Decimal.new("3.75"),
    currency_code: "USD",
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "INDIVIDUAL_001",
    reporting_scenario: "Actual",
    lender_name: "Wells Fargo",
    account_number: "1234567890",
    maturity_date: ~D[2040-06-15],
    payment_frequency: "Monthly",
    monthly_payment: Decimal.new("1850.00"),
    next_payment_date: ~D[2025-01-15],
    description: "30-year fixed rate mortgage",
    is_secured: true,
    collateral_description: "Primary residence at 123 Main St",
    risk_level: "Low",
    priority_level: "High"
  },
  %{
    debt_identifier: "AUTO_LOAN_001",
    debt_name: "Car Loan",
    debt_type: "AutoLoan",
    debt_category: "Personal",
    principal_amount: Decimal.new("25000.00"),
    outstanding_balance: Decimal.new("18000.00"),
    interest_rate: Decimal.new("4.25"),
    currency_code: "USD",
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "INDIVIDUAL_001",
    reporting_scenario: "Actual",
    lender_name: "Chase Auto",
    account_number: "AUTO123456",
    maturity_date: ~D[2027-03-20],
    payment_frequency: "Monthly",
    monthly_payment: Decimal.new("450.00"),
    next_payment_date: ~D[2025-01-20],
    description: "5-year auto loan for 2022 Honda Accord",
    is_secured: true,
    collateral_description: "2022 Honda Accord",
    risk_level: "Medium",
    priority_level: "Medium"
  },
  %{
    debt_identifier: "CREDIT_CARD_001",
    debt_name: "Chase Credit Card",
    debt_type: "CreditCard",
    debt_category: "Revolving",
    principal_amount: Decimal.new("0.00"),
    outstanding_balance: Decimal.new("2500.00"),
    interest_rate: Decimal.new("18.99"),
    currency_code: "USD",
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "INDIVIDUAL_001",
    reporting_scenario: "Actual",
    lender_name: "Chase Bank",
    account_number: "****1234",
    maturity_date: nil,
    payment_frequency: "Monthly",
    monthly_payment: Decimal.new("50.00"),
    next_payment_date: ~D[2025-01-25],
    description: "Chase Freedom Unlimited credit card",
    is_secured: false,
    collateral_description: nil,
    risk_level: "High",
    priority_level: "Low"
  }
]

# Insert sample data
IO.puts("Creating sample financial data...")

Enum.each(sample_assets, fn asset_attrs ->
  case FinancialInstruments.create_asset(asset_attrs) do
    {:ok, asset} ->
      IO.puts("Created asset: #{asset.asset_name}")
    {:error, changeset} ->
      IO.puts("Failed to create asset: #{inspect(changeset.errors)}")
  end
end)

Enum.each(sample_debts, fn debt_attrs ->
  case FinancialInstruments.create_debt_obligation(debt_attrs) do
    {:ok, debt} ->
      IO.puts("Created debt obligation: #{debt.debt_name}")
    {:error, changeset} ->
      IO.puts("Failed to create debt obligation: #{inspect(changeset.errors)}")
  end
end)

# Generate and display a sample financial report
IO.puts("\nGenerating sample financial report...")
report = FinancialInstruments.generate_financial_position_report("INDIVIDUAL_001", "2024-12-31", "USD")

IO.puts("""
Financial Position Report
=========================
Entity: #{report.entity}
Period: #{report.reporting_period}
Currency: #{report.currency}

Total Assets: $#{Decimal.to_string(report.total_assets)}
Total Debt: $#{Decimal.to_string(report.total_debt)}
Net Worth: $#{Decimal.to_string(report.net_worth)}
Debt-to-Asset Ratio: #{Decimal.to_string(report.debt_to_asset_ratio)}
Monthly Debt Payments: $#{Decimal.to_string(report.monthly_debt_payments)}

Assets by Type:
#{Enum.map_join(report.assets_by_type, "\n", fn {type, value} -> "  #{type}: $#{Decimal.to_string(value)}" end)}

Debts by Type:
#{Enum.map_join(report.debts_by_type, "\n", fn {type, value} -> "  #{type}: $#{Decimal.to_string(value)}" end)}
""")

# Validate XBRL compliance
IO.puts("\nValidating XBRL compliance...")
compliance = FinancialInstruments.validate_all_xbrl_compliance()

IO.puts("""
XBRL Compliance Report
======================
Total Assets: #{compliance.summary.total_assets}
Valid Assets: #{compliance.summary.valid_assets}
Total Debts: #{compliance.summary.total_debts}
Valid Debts: #{compliance.summary.valid_debts}
""")

IO.puts("Sample data creation completed!")
