defmodule SoupAndNutz.XBRL.ConceptsTest do
  use ExUnit.Case, async: true
  alias SoupAndNutz.XBRL.Concepts

  describe "asset_types/0" do
    test "returns a list of valid asset types" do
      asset_types = Concepts.asset_types()

      assert is_list(asset_types)
      assert length(asset_types) > 0
      assert "CashAndCashEquivalents" in asset_types
      assert "RealEstate" in asset_types
      assert "InvestmentSecurities" in asset_types
      assert "Goodwill" in asset_types
      assert "DerivativeInstruments" in asset_types
      assert "OtherAssets" in asset_types
    end

    test "all asset types are strings" do
      asset_types = Concepts.asset_types()

      Enum.each(asset_types, fn asset_type ->
        assert is_binary(asset_type)
        assert String.length(asset_type) > 0
      end)
    end

    test "asset types are unique" do
      asset_types = Concepts.asset_types()
      unique_asset_types = Enum.uniq(asset_types)

      assert length(asset_types) == length(unique_asset_types)
    end
  end

  describe "debt_types/0" do
    test "returns a list of valid debt types" do
      debt_types = Concepts.debt_types()

      assert is_list(debt_types)
      assert length(debt_types) > 0
      assert "Mortgage" in debt_types
      assert "CreditCard" in debt_types
      assert "AutoLoan" in debt_types
      assert "AccountsPayable" in debt_types
      assert "PensionObligations" in debt_types
      assert "OtherDebt" in debt_types
    end

    test "all debt types are strings" do
      debt_types = Concepts.debt_types()

      Enum.each(debt_types, fn debt_type ->
        assert is_binary(debt_type)
        assert String.length(debt_type) > 0
      end)
    end

    test "debt types are unique" do
      debt_types = Concepts.debt_types()
      unique_debt_types = Enum.uniq(debt_types)

      assert length(debt_types) == length(unique_debt_types)
    end
  end

  describe "currency_codes/0" do
    test "returns a list of valid currency codes" do
      currency_codes = Concepts.currency_codes()

      assert is_list(currency_codes)
      assert length(currency_codes) > 0
      assert "USD" in currency_codes
      assert "EUR" in currency_codes
      assert "GBP" in currency_codes
      assert "JPY" in currency_codes
      assert "INR" in currency_codes
      assert "BRL" in currency_codes
    end

    test "all currency codes are 3-letter strings" do
      currency_codes = Concepts.currency_codes()

      Enum.each(currency_codes, fn currency_code ->
        assert is_binary(currency_code)
        assert String.length(currency_code) == 3
        assert currency_code == String.upcase(currency_code)
      end)
    end

    test "currency codes are unique" do
      currency_codes = Concepts.currency_codes()
      unique_currency_codes = Enum.uniq(currency_codes)

      assert length(currency_codes) == length(unique_currency_codes)
    end
  end

  describe "payment_frequencies/0" do
    test "returns a list of valid payment frequencies" do
      payment_frequencies = Concepts.payment_frequencies()

      assert is_list(payment_frequencies)
      assert length(payment_frequencies) > 0
      assert "Daily" in payment_frequencies
      assert "Monthly" in payment_frequencies
      assert "Quarterly" in payment_frequencies
      assert "Annually" in payment_frequencies
      assert "AtMaturity" in payment_frequencies
      assert "OnDemand" in payment_frequencies
    end

    test "all payment frequencies are strings" do
      payment_frequencies = Concepts.payment_frequencies()

      Enum.each(payment_frequencies, fn frequency ->
        assert is_binary(frequency)
        assert String.length(frequency) > 0
      end)
    end
  end

  describe "risk_levels/0" do
    test "returns the four standard risk levels" do
      risk_levels = Concepts.risk_levels()

      assert risk_levels == ["Low", "Medium", "High", "VeryHigh"]
    end
  end

  describe "liquidity_levels/0" do
    test "returns the four standard liquidity levels" do
      liquidity_levels = Concepts.liquidity_levels()

      assert liquidity_levels == ["High", "Medium", "Low", "Illiquid"]
    end
  end

  describe "validation_statuses/0" do
    test "returns the five standard validation statuses" do
      validation_statuses = Concepts.validation_statuses()

      assert validation_statuses == ["Pending", "Valid", "Invalid", "Warning", "ReviewRequired"]
    end
  end

  describe "priority_levels/0" do
    test "returns the four standard priority levels" do
      priority_levels = Concepts.priority_levels()

      assert priority_levels == ["Critical", "High", "Medium", "Low"]
    end
  end

  describe "scenario_types/0" do
    test "returns the five standard scenario types" do
      scenario_types = Concepts.scenario_types()

      assert scenario_types == ["Actual", "Budget", "Forecast", "ProForma", "Restated"]
    end
  end

  describe "measurement_bases/0" do
    test "returns a list of valid measurement bases" do
      measurement_bases = Concepts.measurement_bases()

      assert is_list(measurement_bases)
      assert length(measurement_bases) > 0
      assert "HistoricalCost" in measurement_bases
      assert "FairValue" in measurement_bases
      assert "AmortizedCost" in measurement_bases
      assert "MarketValue" in measurement_bases
    end

    test "all measurement bases are strings" do
      measurement_bases = Concepts.measurement_bases()

      Enum.each(measurement_bases, fn basis ->
        assert is_binary(basis)
        assert String.length(basis) > 0
      end)
    end
  end

  describe "business_segments/0" do
    test "returns a list of valid business segments" do
      business_segments = Concepts.business_segments()

      assert is_list(business_segments)
      assert length(business_segments) > 0
      assert "Geographic" in business_segments
      assert "Product" in business_segments
      assert "OperatingSegment" in business_segments
    end
  end

  describe "geographic_regions/0" do
    test "returns a list of valid geographic regions" do
      geographic_regions = Concepts.geographic_regions()

      assert is_list(geographic_regions)
      assert length(geographic_regions) > 0
      assert "NorthAmerica" in geographic_regions
      assert "Europe" in geographic_regions
      assert "UnitedStates" in geographic_regions
      assert "China" in geographic_regions
    end
  end

  describe "industry_classifications/0" do
    test "returns a list of valid industry classifications" do
      industry_classifications = Concepts.industry_classifications()

      assert is_list(industry_classifications)
      assert length(industry_classifications) > 0
      assert "Manufacturing" in industry_classifications
      assert "Technology" in industry_classifications
      assert "Finance" in industry_classifications
      assert "Healthcare" in industry_classifications
    end
  end

  describe "financial_statement_types/0" do
    test "returns a list of valid financial statement types" do
      financial_statement_types = Concepts.financial_statement_types()

      assert is_list(financial_statement_types)
      assert length(financial_statement_types) > 0
      assert "BalanceSheet" in financial_statement_types
      assert "IncomeStatement" in financial_statement_types
      assert "CashFlowStatement" in financial_statement_types
      assert "NotesToFinancialStatements" in financial_statement_types
    end
  end

  describe "audit_opinions/0" do
    test "returns a list of valid audit opinions" do
      audit_opinions = Concepts.audit_opinions()

      assert is_list(audit_opinions)
      assert length(audit_opinions) > 0
      assert "Unqualified" in audit_opinions
      assert "Qualified" in audit_opinions
      assert "Adverse" in audit_opinions
      assert "GoingConcern" in audit_opinions
    end
  end

  describe "regulatory_frameworks/0" do
    test "returns a list of valid regulatory frameworks" do
      regulatory_frameworks = Concepts.regulatory_frameworks()

      assert is_list(regulatory_frameworks)
      assert length(regulatory_frameworks) > 0
      assert "IFRS" in regulatory_frameworks
      assert "USGAAP" in regulatory_frameworks
      assert "UKGAAP" in regulatory_frameworks
      assert "CanadianGAAP" in regulatory_frameworks
    end
  end

  describe "entity_types/0" do
    test "returns a list of valid entity types" do
      entity_types = Concepts.entity_types()

      assert is_list(entity_types)
      assert length(entity_types) > 0
      assert "Corporation" in entity_types
      assert "Partnership" in entity_types
      assert "LimitedLiabilityCompany" in entity_types
      assert "NonProfit" in entity_types
    end
  end

  describe "reporting_periods/0" do
    test "returns a list of valid reporting periods" do
      reporting_periods = Concepts.reporting_periods()

      assert is_list(reporting_periods)
      assert length(reporting_periods) > 0
      assert "Monthly" in reporting_periods
      assert "Quarterly" in reporting_periods
      assert "Annual" in reporting_periods
      assert "TrailingTwelveMonths" in reporting_periods
    end
  end

  describe "consolidation_levels/0" do
    test "returns a list of valid consolidation levels" do
      consolidation_levels = Concepts.consolidation_levels()

      assert is_list(consolidation_levels)
      assert length(consolidation_levels) > 0
      assert "Consolidated" in consolidation_levels
      assert "ParentOnly" in consolidation_levels
      assert "Subsidiary" in consolidation_levels
      assert "JointVenture" in consolidation_levels
    end
  end

  describe "disclosure_types/0" do
    test "returns a list of valid disclosure types" do
      disclosure_types = Concepts.disclosure_types()

      assert is_list(disclosure_types)
      assert length(disclosure_types) > 0
      assert "AccountingPolicies" in disclosure_types
      assert "RelatedPartyTransactions" in disclosure_types
      assert "RiskManagement" in disclosure_types
      assert "FairValueMeasurements" in disclosure_types
    end
  end

  describe "materiality_levels/0" do
    test "returns a list of valid materiality levels" do
      materiality_levels = Concepts.materiality_levels()

      assert is_list(materiality_levels)
      assert length(materiality_levels) > 0
      assert "Material" in materiality_levels
      assert "Immaterial" in materiality_levels
      assert "Significant" in materiality_levels
      assert "Threshold" in materiality_levels
    end
  end

  describe "data_quality_indicators/0" do
    test "returns a list of valid data quality indicators" do
      data_quality_indicators = Concepts.data_quality_indicators()

      assert is_list(data_quality_indicators)
      assert length(data_quality_indicators) > 0
      assert "HighQuality" in data_quality_indicators
      assert "Audited" in data_quality_indicators
      assert "Unaudited" in data_quality_indicators
      assert "Estimated" in data_quality_indicators
    end
  end

  describe "transaction_types/0" do
    test "returns a list of valid transaction types" do
      transaction_types = Concepts.transaction_types()

      assert is_list(transaction_types)
      assert length(transaction_types) > 0
      assert "Purchase" in transaction_types
      assert "Sale" in transaction_types
      assert "Transfer" in transaction_types
      assert "Dividend" in transaction_types
      assert "Loan" in transaction_types
    end
  end

  describe "valuation_methods/0" do
    test "returns a list of valid valuation methods" do
      valuation_methods = Concepts.valuation_methods()

      assert is_list(valuation_methods)
      assert length(valuation_methods) > 0
      assert "MarketApproach" in valuation_methods
      assert "IncomeApproach" in valuation_methods
      assert "CostApproach" in valuation_methods
      assert "DiscountedCashFlow" in valuation_methods
    end
  end

  describe "compliance_statuses/0" do
    test "returns a list of valid compliance statuses" do
      compliance_statuses = Concepts.compliance_statuses()

      assert is_list(compliance_statuses)
      assert length(compliance_statuses) > 0
      assert "Compliant" in compliance_statuses
      assert "NonCompliant" in compliance_statuses
      assert "UnderReview" in compliance_statuses
      assert "Exempt" in compliance_statuses
    end
  end

  describe "document_types/0" do
    test "returns a list of valid document types" do
      document_types = Concepts.document_types()

      assert is_list(document_types)
      assert length(document_types) > 0
      assert "FinancialStatement" in document_types
      assert "AnnualReport" in document_types
      assert "Form10K" in document_types
      assert "XBRLInstance" in document_types
    end
  end

  describe "integration" do
    test "all concept lists are non-empty" do
      assert length(Concepts.asset_types()) > 0
      assert length(Concepts.debt_types()) > 0
      assert length(Concepts.currency_codes()) > 0
      assert length(Concepts.payment_frequencies()) > 0
      assert length(Concepts.risk_levels()) > 0
      assert length(Concepts.liquidity_levels()) > 0
      assert length(Concepts.validation_statuses()) > 0
      assert length(Concepts.priority_levels()) > 0
      assert length(Concepts.scenario_types()) > 0
      assert length(Concepts.measurement_bases()) > 0
      assert length(Concepts.business_segments()) > 0
      assert length(Concepts.geographic_regions()) > 0
      assert length(Concepts.industry_classifications()) > 0
      assert length(Concepts.financial_statement_types()) > 0
      assert length(Concepts.audit_opinions()) > 0
      assert length(Concepts.regulatory_frameworks()) > 0
      assert length(Concepts.entity_types()) > 0
      assert length(Concepts.reporting_periods()) > 0
      assert length(Concepts.consolidation_levels()) > 0
      assert length(Concepts.disclosure_types()) > 0
      assert length(Concepts.materiality_levels()) > 0
      assert length(Concepts.data_quality_indicators()) > 0
      assert length(Concepts.transaction_types()) > 0
      assert length(Concepts.valuation_methods()) > 0
      assert length(Concepts.compliance_statuses()) > 0
      assert length(Concepts.document_types()) > 0
    end

    test "no concept lists contain nil values" do
      Enum.each(Concepts.asset_types(), &assert not is_nil(&1))
      Enum.each(Concepts.debt_types(), &assert not is_nil(&1))
      Enum.each(Concepts.currency_codes(), &assert not is_nil(&1))
      Enum.each(Concepts.payment_frequencies(), &assert not is_nil(&1))
      Enum.each(Concepts.risk_levels(), &assert not is_nil(&1))
      Enum.each(Concepts.liquidity_levels(), &assert not is_nil(&1))
      Enum.each(Concepts.validation_statuses(), &assert not is_nil(&1))
      Enum.each(Concepts.priority_levels(), &assert not is_nil(&1))
      Enum.each(Concepts.scenario_types(), &assert not is_nil(&1))
      Enum.each(Concepts.measurement_bases(), &assert not is_nil(&1))
      Enum.each(Concepts.business_segments(), &assert not is_nil(&1))
      Enum.each(Concepts.geographic_regions(), &assert not is_nil(&1))
      Enum.each(Concepts.industry_classifications(), &assert not is_nil(&1))
      Enum.each(Concepts.financial_statement_types(), &assert not is_nil(&1))
      Enum.each(Concepts.audit_opinions(), &assert not is_nil(&1))
      Enum.each(Concepts.regulatory_frameworks(), &assert not is_nil(&1))
      Enum.each(Concepts.entity_types(), &assert not is_nil(&1))
      Enum.each(Concepts.reporting_periods(), &assert not is_nil(&1))
      Enum.each(Concepts.consolidation_levels(), &assert not is_nil(&1))
      Enum.each(Concepts.disclosure_types(), &assert not is_nil(&1))
      Enum.each(Concepts.materiality_levels(), &assert not is_nil(&1))
      Enum.each(Concepts.data_quality_indicators(), &assert not is_nil(&1))
      Enum.each(Concepts.transaction_types(), &assert not is_nil(&1))
      Enum.each(Concepts.valuation_methods(), &assert not is_nil(&1))
      Enum.each(Concepts.compliance_statuses(), &assert not is_nil(&1))
      Enum.each(Concepts.document_types(), &assert not is_nil(&1))
    end
  end
end
