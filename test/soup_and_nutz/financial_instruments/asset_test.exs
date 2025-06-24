defmodule SoupAndNutz.FinancialInstruments.AssetTest do
  use SoupAndNutz.DataCase, async: true
  alias SoupAndNutz.FinancialInstruments.Asset
  alias SoupAndNutz.XBRL.Concepts

  @valid_attrs %{
    asset_identifier: "TEST_001",
    asset_name: "Test Asset",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Checking",
    fair_value: Decimal.new("10000.00"),
    book_value: Decimal.new("10000.00"),
    currency_code: "USD",
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "TEST_ENTITY",
    reporting_scenario: "Actual",
    description: "Test asset description",
    location: "Test Bank",
    custodian: "Test Bank",
    risk_level: "Low",
    liquidity_level: "High"
  }

  @invalid_attrs %{
    asset_identifier: nil,
    asset_name: nil,
    asset_type: nil,
    currency_code: nil,
    measurement_date: nil,
    reporting_period: nil,
    reporting_entity: nil
  }

  describe "changeset/2" do
    test "changeset with valid attributes" do
      changeset = Asset.changeset(%Asset{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Asset.changeset(%Asset{}, @invalid_attrs)
      refute changeset.valid?
    end

    test "changeset requires asset_identifier" do
      attrs = Map.delete(@valid_attrs, :asset_identifier)
      changeset = Asset.changeset(%Asset{}, attrs)
      refute changeset.valid?
      assert %{asset_identifier: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires asset_name" do
      attrs = Map.delete(@valid_attrs, :asset_name)
      changeset = Asset.changeset(%Asset{}, attrs)
      refute changeset.valid?
      assert %{asset_name: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires asset_type" do
      attrs = Map.delete(@valid_attrs, :asset_type)
      changeset = Asset.changeset(%Asset{}, attrs)
      refute changeset.valid?
      assert %{asset_type: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires currency_code" do
      attrs = Map.delete(@valid_attrs, :currency_code)
      changeset = Asset.changeset(%Asset{}, attrs)
      refute changeset.valid?
      assert %{currency_code: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires measurement_date" do
      attrs = Map.delete(@valid_attrs, :measurement_date)
      changeset = Asset.changeset(%Asset{}, attrs)
      refute changeset.valid?
      assert %{measurement_date: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires reporting_period" do
      attrs = Map.delete(@valid_attrs, :reporting_period)
      changeset = Asset.changeset(%Asset{}, attrs)
      refute changeset.valid?
      assert %{reporting_period: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires reporting_entity" do
      attrs = Map.delete(@valid_attrs, :reporting_entity)
      changeset = Asset.changeset(%Asset{}, attrs)
      refute changeset.valid?
      assert %{reporting_entity: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset validates asset_type inclusion" do
      attrs = Map.put(@valid_attrs, :asset_type, "InvalidType")
      changeset = Asset.changeset(%Asset{}, attrs)
      refute changeset.valid?
      assert %{asset_type: ["is invalid"]} = errors_on(changeset)
    end

    test "changeset validates currency_code inclusion" do
      attrs = Map.put(@valid_attrs, :currency_code, "INVALID")
      changeset = Asset.changeset(%Asset{}, attrs)
      refute changeset.valid?
      assert %{currency_code: ["is invalid"]} = errors_on(changeset)
    end

    test "changeset validates risk_level inclusion" do
      attrs = Map.put(@valid_attrs, :risk_level, "Invalid")
      changeset = Asset.changeset(%Asset{}, attrs)
      refute changeset.valid?
      assert %{risk_level: ["is invalid"]} = errors_on(changeset)
    end

    test "changeset validates liquidity_level inclusion" do
      attrs = Map.put(@valid_attrs, :liquidity_level, "Invalid")
      changeset = Asset.changeset(%Asset{}, attrs)
      refute changeset.valid?
      assert %{liquidity_level: ["is invalid"]} = errors_on(changeset)
    end

    test "changeset validates fair_value is non-negative" do
      attrs = Map.put(@valid_attrs, :fair_value, Decimal.new("-1000.00"))
      changeset = Asset.changeset(%Asset{}, attrs)
      refute changeset.valid?
      assert %{fair_value: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "changeset validates book_value is non-negative" do
      attrs = Map.put(@valid_attrs, :book_value, Decimal.new("-1000.00"))
      changeset = Asset.changeset(%Asset{}, attrs)
      refute changeset.valid?
      assert %{book_value: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "changeset validates asset_identifier format" do
      attrs = Map.put(@valid_attrs, :asset_identifier, "invalid-identifier")
      changeset = Asset.changeset(%Asset{}, attrs)
      refute changeset.valid?
      assert %{asset_identifier: ["must contain only uppercase letters, numbers, underscores, and hyphens"]} = errors_on(changeset)
    end

    test "changeset enforces unique asset_identifier" do
      # First, create an asset
      {:ok, _asset} = Repo.insert(Asset.changeset(%Asset{}, @valid_attrs))

      # Try to create another with the same identifier
      changeset = Asset.changeset(%Asset{}, @valid_attrs)
      assert {:error, changeset} = Repo.insert(changeset)
      assert %{asset_identifier: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "asset_types/0" do
    test "returns the same list as Concepts.asset_types" do
      assert Asset.asset_types() == Concepts.asset_types()
    end
  end

  describe "currency_codes/0" do
    test "returns the same list as Concepts.currency_codes" do
      assert Asset.currency_codes() == Concepts.currency_codes()
    end
  end

  describe "total_fair_value/2" do
    test "calculates total fair value for assets in given currency" do
      assets = [
        %Asset{fair_value: Decimal.new("1000.00"), currency_code: "USD"},
        %Asset{fair_value: Decimal.new("2000.00"), currency_code: "USD"},
        %Asset{fair_value: Decimal.new("500.00"), currency_code: "EUR"}
      ]

      total = Asset.total_fair_value(assets, "USD")
      assert Decimal.eq?(total, Decimal.new("3000.00"))
    end

    test "returns zero for empty list" do
      total = Asset.total_fair_value([], "USD")
      assert Decimal.eq?(total, Decimal.new("0"))
    end

    test "returns zero when no assets match currency" do
      assets = [
        %Asset{fair_value: Decimal.new("1000.00"), currency_code: "EUR"}
      ]

      total = Asset.total_fair_value(assets, "USD")
      assert Decimal.eq?(total, Decimal.new("0"))
    end

    test "handles nil fair_value" do
      assets = [
        %Asset{fair_value: nil, currency_code: "USD"},
        %Asset{fair_value: Decimal.new("1000.00"), currency_code: "USD"}
      ]

      total = Asset.total_fair_value(assets, "USD")
      assert Decimal.eq?(total, Decimal.new("1000.00"))
    end

    test "uses USD as default currency" do
      assets = [
        %Asset{fair_value: Decimal.new("1000.00"), currency_code: "USD"}
      ]

      total = Asset.total_fair_value(assets)
      assert Decimal.eq?(total, Decimal.new("1000.00"))
    end
  end

  describe "validate_xbrl_rules/1" do
    test "returns valid for asset with reasonable values" do
      asset = %Asset{
        fair_value: Decimal.new("10000.00"),
        book_value: Decimal.new("10000.00"),
        measurement_date: ~D[2024-12-31]
      }

      {valid, errors} = Asset.validate_xbrl_rules(asset)
      assert valid
      assert errors == []
    end

    test "returns invalid when fair value differs significantly from book value" do
      asset = %Asset{
        fair_value: Decimal.new("20000.00"),
        book_value: Decimal.new("10000.00"),
        measurement_date: ~D[2024-12-31]
      }

      {valid, errors} = Asset.validate_xbrl_rules(asset)
      refute valid
      assert length(errors) == 1
      assert {"fair_value", "Significant difference from book value requires explanation"} in errors
    end

    test "returns invalid when measurement date is in the future" do
      future_date = Date.add(Date.utc_today(), 1)
      asset = %Asset{
        fair_value: Decimal.new("10000.00"),
        book_value: Decimal.new("10000.00"),
        measurement_date: future_date
      }

      {valid, errors} = Asset.validate_xbrl_rules(asset)
      refute valid
      assert length(errors) == 1
      assert {"measurement_date", "Measurement date cannot be in the future"} in errors
    end

    test "handles nil values gracefully" do
      asset = %Asset{
        fair_value: nil,
        book_value: nil,
        measurement_date: nil
      }

      {valid, errors} = Asset.validate_xbrl_rules(asset)
      assert valid
      assert errors == []
    end

    test "allows small differences between fair value and book value" do
      asset = %Asset{
        fair_value: Decimal.new("10500.00"),
        book_value: Decimal.new("10000.00"),
        measurement_date: ~D[2024-12-31]
      }

      {valid, errors} = Asset.validate_xbrl_rules(asset)
      assert valid
      assert errors == []
    end
  end
end
