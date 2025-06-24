defmodule SoupAndNutz.XBRL.Concepts do
  @moduledoc """
  Provides XBRL concept enumerations and helpers for financial domain modeling.
  This module is designed to be reusable and eventually extracted as a standalone library.
  """

  # Asset Types (XBRL-inspired)
  @asset_types [
    "CashAndCashEquivalents",
    "MarketableSecurities",
    "AccountsReceivable",
    "Inventory",
    "PrepaidExpenses",
    "PropertyPlantAndEquipment",
    "IntangibleAssets",
    "InvestmentSecurities",
    "RealEstate",
    "Vehicles",
    "Collectibles",
    "Goodwill",
    "DeferredTaxAssets",
    "RestrictedCash",
    "DerivativeInstruments",
    "OtherAssets"
  ]

  def asset_types, do: @asset_types

  # Debt Types (XBRL-inspired)
  @debt_types [
    "ShortTermDebt",
    "LongTermDebt",
    "Mortgage",
    "CreditCard",
    "StudentLoan",
    "AutoLoan",
    "PersonalLoan",
    "BusinessLoan",
    "LineOfCredit",
    "Bond",
    "LeaseObligation",
    "AccountsPayable",
    "AccruedExpenses",
    "DeferredRevenue",
    "PensionObligations",
    "OtherDebt"
  ]

  def debt_types, do: @debt_types

  # Currency Codes (ISO 4217)
  @currency_codes [
    "USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY",
    "INR", "BRL", "MXN", "KRW", "SGD", "HKD", "SEK", "NOK",
    "DKK", "PLN", "CZK", "HUF", "RUB", "TRY", "ZAR", "NZD"
  ]

  def currency_codes, do: @currency_codes

  # Payment Frequencies
  @payment_frequencies [
    "Daily",
    "Weekly",
    "BiWeekly",
    "Monthly",
    "Quarterly",
    "SemiAnnually",
    "Annually",
    "AtMaturity",
    "Variable",
    "OnDemand"
  ]

  def payment_frequencies, do: @payment_frequencies

  # Risk Levels
  @risk_levels ["Low", "Medium", "High", "VeryHigh"]
  def risk_levels, do: @risk_levels

  # Liquidity Levels
  @liquidity_levels ["High", "Medium", "Low", "Illiquid"]
  def liquidity_levels, do: @liquidity_levels

  # Validation Statuses
  @validation_statuses ["Pending", "Valid", "Invalid", "Warning", "ReviewRequired"]
  def validation_statuses, do: @validation_statuses

  # Priority Levels
  @priority_levels ["Critical", "High", "Medium", "Low"]
  def priority_levels, do: @priority_levels

  # XBRL scenario types
  @scenario_types ["Actual", "Budget", "Forecast", "ProForma", "Restated"]
  def scenario_types, do: @scenario_types

  # Measurement Bases (IFRS/US GAAP)
  @measurement_bases [
    "HistoricalCost",
    "FairValue",
    "AmortizedCost",
    "NetRealizableValue",
    "PresentValue",
    "ReplacementCost",
    "CurrentCost",
    "MarketValue"
  ]

  def measurement_bases, do: @measurement_bases

  # Business Segments
  @business_segments [
    "Geographic",
    "Product",
    "Service",
    "Customer",
    "DistributionChannel",
    "OperatingSegment",
    "ReportableSegment"
  ]

  def business_segments, do: @business_segments

  # Geographic Regions
  @geographic_regions [
    "NorthAmerica",
    "SouthAmerica",
    "Europe",
    "AsiaPacific",
    "MiddleEast",
    "Africa",
    "UnitedStates",
    "Canada",
    "Mexico",
    "UnitedKingdom",
    "Germany",
    "France",
    "Japan",
    "China",
    "India",
    "Australia",
    "Brazil",
    "Russia"
  ]

  def geographic_regions, do: @geographic_regions

  # Industry Classifications (SIC/NAICS)
  @industry_classifications [
    "Agriculture",
    "Mining",
    "Construction",
    "Manufacturing",
    "Transportation",
    "Communications",
    "Utilities",
    "WholesaleTrade",
    "RetailTrade",
    "Finance",
    "Insurance",
    "RealEstate",
    "Services",
    "PublicAdministration",
    "Technology",
    "Healthcare",
    "Education",
    "Entertainment"
  ]

  def industry_classifications, do: @industry_classifications

  # Financial Statement Types
  @financial_statement_types [
    "BalanceSheet",
    "IncomeStatement",
    "CashFlowStatement",
    "StatementOfEquity",
    "StatementOfComprehensiveIncome",
    "NotesToFinancialStatements",
    "ManagementDiscussionAndAnalysis"
  ]

  def financial_statement_types, do: @financial_statement_types

  # Audit Opinions
  @audit_opinions [
    "Unqualified",
    "Qualified",
    "Adverse",
    "Disclaimer",
    "GoingConcern",
    "EmphasisOfMatter"
  ]

  def audit_opinions, do: @audit_opinions

  # Regulatory Frameworks
  @regulatory_frameworks [
    "IFRS",
    "USGAAP",
    "UKGAAP",
    "CanadianGAAP",
    "AustralianGAAP",
    "JapaneseGAAP",
    "ChineseGAAP",
    "IndianGAAP",
    "BrazilianGAAP",
    "GermanGAAP"
  ]

  def regulatory_frameworks, do: @regulatory_frameworks

  # Entity Types
  @entity_types [
    "Corporation",
    "Partnership",
    "LimitedLiabilityCompany",
    "SoleProprietorship",
    "Trust",
    "Foundation",
    "NonProfit",
    "Government",
    "Subsidiary",
    "JointVenture",
    "Branch"
  ]

  def entity_types, do: @entity_types

  # Reporting Periods
  @reporting_periods [
    "Monthly",
    "Quarterly",
    "SemiAnnual",
    "Annual",
    "Interim",
    "YearToDate",
    "TrailingTwelveMonths"
  ]

  def reporting_periods, do: @reporting_periods

  # Consolidation Levels
  @consolidation_levels [
    "Consolidated",
    "ParentOnly",
    "Subsidiary",
    "EquityMethod",
    "Proportional",
    "JointVenture"
  ]

  def consolidation_levels, do: @consolidation_levels

  # Disclosure Types
  @disclosure_types [
    "AccountingPolicies",
    "SignificantAccountingEstimates",
    "RelatedPartyTransactions",
    "Contingencies",
    "SubsequentEvents",
    "SegmentInformation",
    "RiskManagement",
    "FairValueMeasurements"
  ]

  def disclosure_types, do: @disclosure_types

  # Materiality Levels
  @materiality_levels [
    "Material",
    "Immaterial",
    "Significant",
    "Trivial",
    "Threshold"
  ]

  def materiality_levels, do: @materiality_levels

  # Data Quality Indicators
  @data_quality_indicators [
    "HighQuality",
    "MediumQuality",
    "LowQuality",
    "Estimated",
    "Provisional",
    "Audited",
    "Unaudited",
    "Reviewed"
  ]

  def data_quality_indicators, do: @data_quality_indicators

  # Transaction Types
  @transaction_types [
    "Purchase",
    "Sale",
    "Transfer",
    "Exchange",
    "Gift",
    "Inheritance",
    "Dividend",
    "Interest",
    "Rental",
    "Lease",
    "Loan",
    "Repayment"
  ]

  def transaction_types, do: @transaction_types

  # Valuation Methods
  @valuation_methods [
    "MarketApproach",
    "IncomeApproach",
    "CostApproach",
    "DiscountedCashFlow",
    "ComparableSales",
    "ReplacementCost",
    "LiquidationValue",
    "BookValue"
  ]

  def valuation_methods, do: @valuation_methods

  # Compliance Status
  @compliance_statuses [
    "Compliant",
    "NonCompliant",
    "UnderReview",
    "Exempt",
    "Pending",
    "Waived"
  ]

  def compliance_statuses, do: @compliance_statuses

  # Document Types
  @document_types [
    "FinancialStatement",
    "AnnualReport",
    "QuarterlyReport",
    "Prospectus",
    "RegistrationStatement",
    "ProxyStatement",
    "Form10K",
    "Form10Q",
    "Form8K",
    "XBRLInstance",
    "XBRLTaxonomy"
  ]

  def document_types, do: @document_types

  # Add more XBRL concepts as needed...
end
