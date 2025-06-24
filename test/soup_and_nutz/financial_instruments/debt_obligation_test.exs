defmodule SoupAndNutz.FinancialInstruments.DebtObligationTest do
  use SoupAndNutz.DataCase, async: true
  alias SoupAndNutz.FinancialInstruments.DebtObligation
  alias SoupAndNutz.XBRL.Concepts

  @valid_attrs %{
    debt_identifier: "TEST_DEBT_001",
    debt_name: "Test Debt",
    debt_type: "Mortgage",
    debt_category: "Residential",
    principal_amount: Decimal.new("200000.00"),
    outstanding_balance: Decimal.new("180000.00"),
    interest_rate: Decimal.new("3.75"),
    currency_code: "USD",
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "TEST_ENTITY",
    reporting_scenario: "Actual",
    lender_name: "Test Bank",
    account_number: "123456789",
    maturity_date: ~D[2040-06-15],
    payment_frequency: "Monthly",
    monthly_payment: Decimal.new("1000.00"),
    next_payment_date: ~D[2025-01-15],
    description: "Test debt description",
    is_secured: true,
    collateral_description: "Test collateral",
    risk_level: "Low",
    priority_level: "High"
  }

  @invalid_attrs %{
    debt_identifier: nil,
    debt_name: nil,
    debt_type: nil,
    currency_code: nil,
    measurement_date: nil,
    reporting_period: nil,
    reporting_entity: nil
  }

  describe "changeset/2" do
    test "changeset with valid attributes" do
      changeset = DebtObligation.changeset(%DebtObligation{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = DebtObligation.changeset(%DebtObligation{}, @invalid_attrs)
      refute changeset.valid?
    end

    test "changeset requires debt_identifier" do
      attrs = Map.delete(@valid_attrs, :debt_identifier)
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{debt_identifier: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires debt_name" do
      attrs = Map.delete(@valid_attrs, :debt_name)
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{debt_name: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires debt_type" do
      attrs = Map.delete(@valid_attrs, :debt_type)
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{debt_type: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires currency_code" do
      attrs = Map.delete(@valid_attrs, :currency_code)
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{currency_code: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires measurement_date" do
      attrs = Map.delete(@valid_attrs, :measurement_date)
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{measurement_date: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires reporting_period" do
      attrs = Map.delete(@valid_attrs, :reporting_period)
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{reporting_period: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires reporting_entity" do
      attrs = Map.delete(@valid_attrs, :reporting_entity)
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{reporting_entity: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset validates debt_type inclusion" do
      attrs = Map.put(@valid_attrs, :debt_type, "InvalidType")
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{debt_type: ["is invalid"]} = errors_on(changeset)
    end

    test "changeset validates currency_code inclusion" do
      attrs = Map.put(@valid_attrs, :currency_code, "INVALID")
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{currency_code: ["is invalid"]} = errors_on(changeset)
    end

    test "changeset validates payment_frequency inclusion" do
      attrs = Map.put(@valid_attrs, :payment_frequency, "Invalid")
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{payment_frequency: ["is invalid"]} = errors_on(changeset)
    end

    test "changeset validates risk_level inclusion" do
      attrs = Map.put(@valid_attrs, :risk_level, "Invalid")
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{risk_level: ["is invalid"]} = errors_on(changeset)
    end

    test "changeset validates priority_level inclusion" do
      attrs = Map.put(@valid_attrs, :priority_level, "Invalid")
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{priority_level: ["is invalid"]} = errors_on(changeset)
    end

    test "changeset validates principal_amount is positive" do
      attrs = Map.put(@valid_attrs, :principal_amount, Decimal.new("0"))
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{principal_amount: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "changeset validates outstanding_balance is non-negative" do
      attrs = Map.put(@valid_attrs, :outstanding_balance, Decimal.new("-1000.00"))
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{outstanding_balance: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "changeset validates interest_rate is non-negative" do
      attrs = Map.put(@valid_attrs, :interest_rate, Decimal.new("-1.00"))
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{interest_rate: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "changeset validates monthly_payment is non-negative" do
      attrs = Map.put(@valid_attrs, :monthly_payment, Decimal.new("-100.00"))
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{monthly_payment: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "changeset validates debt_identifier format" do
      attrs = Map.put(@valid_attrs, :debt_identifier, "invalid-identifier")
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{debt_identifier: ["must contain only uppercase letters, numbers, underscores, and hyphens"]} = errors_on(changeset)
    end

    test "changeset enforces unique debt_identifier" do
      # First, create a debt obligation
      {:ok, _debt} = Repo.insert(DebtObligation.changeset(%DebtObligation{}, @valid_attrs))

      # Try to create another with the same identifier
      changeset = DebtObligation.changeset(%DebtObligation{}, @valid_attrs)
      assert {:error, changeset} = Repo.insert(changeset)
      assert %{debt_identifier: ["has already been taken"]} = errors_on(changeset)
    end

    test "changeset validates outstanding balance does not exceed principal amount" do
      attrs = Map.put(@valid_attrs, :outstanding_balance, Decimal.new("250000.00"))
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{outstanding_balance: ["Outstanding balance cannot exceed principal amount"]} = errors_on(changeset)
    end

    test "changeset validates maturity date is not before measurement date" do
      attrs = Map.put(@valid_attrs, :maturity_date, ~D[2020-01-01])
      changeset = DebtObligation.changeset(%DebtObligation{}, attrs)
      refute changeset.valid?
      assert %{maturity_date: ["Maturity date cannot be before measurement date"]} = errors_on(changeset)
    end
  end

  describe "debt_types/0" do
    test "returns the same list as Concepts.debt_types" do
      assert DebtObligation.debt_types() == Concepts.debt_types()
    end
  end

  describe "currency_codes/0" do
    test "returns the same list as Concepts.currency_codes" do
      assert DebtObligation.currency_codes() == Concepts.currency_codes()
    end
  end

  describe "payment_frequencies/0" do
    test "returns the same list as Concepts.payment_frequencies" do
      assert DebtObligation.payment_frequencies() == Concepts.payment_frequencies()
    end
  end

  describe "total_outstanding_debt/2" do
    test "calculates total outstanding debt for debts in given currency" do
      debts = [
        %DebtObligation{outstanding_balance: Decimal.new("10000.00"), currency_code: "USD"},
        %DebtObligation{outstanding_balance: Decimal.new("20000.00"), currency_code: "USD"},
        %DebtObligation{outstanding_balance: Decimal.new("5000.00"), currency_code: "EUR"}
      ]

      total = DebtObligation.total_outstanding_debt(debts, "USD")
      assert Decimal.eq?(total, Decimal.new("30000.00"))
    end

    test "returns zero for empty list" do
      total = DebtObligation.total_outstanding_debt([], "USD")
      assert Decimal.eq?(total, Decimal.new("0"))
    end

    test "returns zero when no debts match currency" do
      debts = [
        %DebtObligation{outstanding_balance: Decimal.new("10000.00"), currency_code: "EUR"}
      ]

      total = DebtObligation.total_outstanding_debt(debts, "USD")
      assert Decimal.eq?(total, Decimal.new("0"))
    end

    test "handles nil outstanding_balance" do
      debts = [
        %DebtObligation{outstanding_balance: nil, currency_code: "USD"},
        %DebtObligation{outstanding_balance: Decimal.new("10000.00"), currency_code: "USD"}
      ]

      total = DebtObligation.total_outstanding_debt(debts, "USD")
      assert Decimal.eq?(total, Decimal.new("10000.00"))
    end

    test "uses USD as default currency" do
      debts = [
        %DebtObligation{outstanding_balance: Decimal.new("10000.00"), currency_code: "USD"}
      ]

      total = DebtObligation.total_outstanding_debt(debts)
      assert Decimal.eq?(total, Decimal.new("10000.00"))
    end
  end

  describe "total_monthly_payments/2" do
    test "calculates total monthly payments for debts in given currency" do
      debts = [
        %DebtObligation{monthly_payment: Decimal.new("500.00"), currency_code: "USD"},
        %DebtObligation{monthly_payment: Decimal.new("750.00"), currency_code: "USD"},
        %DebtObligation{monthly_payment: Decimal.new("200.00"), currency_code: "EUR"}
      ]

      total = DebtObligation.total_monthly_payments(debts, "USD")
      assert Decimal.eq?(total, Decimal.new("1250.00"))
    end

    test "returns zero for empty list" do
      total = DebtObligation.total_monthly_payments([], "USD")
      assert Decimal.eq?(total, Decimal.new("0"))
    end

    test "handles nil monthly_payment" do
      debts = [
        %DebtObligation{monthly_payment: nil, currency_code: "USD"},
        %DebtObligation{monthly_payment: Decimal.new("500.00"), currency_code: "USD"}
      ]

      total = DebtObligation.total_monthly_payments(debts, "USD")
      assert Decimal.eq?(total, Decimal.new("500.00"))
    end
  end

  describe "validate_xbrl_rules/1" do
    test "returns valid for debt with reasonable values" do
      debt = %DebtObligation{
        outstanding_balance: Decimal.new("180000.00"),
        principal_amount: Decimal.new("200000.00"),
        maturity_date: ~D[2040-06-15],
        is_active: true,
        interest_rate: Decimal.new("3.75")
      }

      {valid, errors} = DebtObligation.validate_xbrl_rules(debt)
      assert valid
      assert errors == []
    end

    test "returns invalid when outstanding balance exceeds principal amount" do
      debt = %DebtObligation{
        outstanding_balance: Decimal.new("250000.00"),
        principal_amount: Decimal.new("200000.00"),
        maturity_date: ~D[2040-06-15],
        is_active: true,
        interest_rate: Decimal.new("3.75")
      }

      {valid, errors} = DebtObligation.validate_xbrl_rules(debt)
      refute valid
      assert length(errors) == 1
      assert {"outstanding_balance", "Outstanding balance cannot exceed principal amount"} in errors
    end

    test "returns invalid when maturity date is in the past for active debt" do
      past_date = Date.add(Date.utc_today(), -1)
      debt = %DebtObligation{
        outstanding_balance: Decimal.new("180000.00"),
        principal_amount: Decimal.new("200000.00"),
        maturity_date: past_date,
        is_active: true,
        interest_rate: Decimal.new("3.75")
      }

      {valid, errors} = DebtObligation.validate_xbrl_rules(debt)
      refute valid
      assert length(errors) == 1
      assert {"maturity_date", "Maturity date should be in the future for active debts"} in errors
    end

    test "returns invalid when interest rate is unusually high" do
      debt = %DebtObligation{
        outstanding_balance: Decimal.new("180000.00"),
        principal_amount: Decimal.new("200000.00"),
        maturity_date: ~D[2040-06-15],
        is_active: true,
        interest_rate: Decimal.new("75.00")
      }

      {valid, errors} = DebtObligation.validate_xbrl_rules(debt)
      refute valid
      assert length(errors) == 1
      assert {"interest_rate", "Interest rate seems unusually high"} in errors
    end

    test "handles nil values gracefully" do
      debt = %DebtObligation{
        outstanding_balance: nil,
        principal_amount: nil,
        maturity_date: nil,
        is_active: nil,
        interest_rate: nil
      }

      {valid, errors} = DebtObligation.validate_xbrl_rules(debt)
      assert valid
      assert errors == []
    end

    test "allows reasonable interest rates" do
      debt = %DebtObligation{
        outstanding_balance: Decimal.new("180000.00"),
        principal_amount: Decimal.new("200000.00"),
        maturity_date: ~D[2040-06-15],
        is_active: true,
        interest_rate: Decimal.new("25.00")
      }

      {valid, errors} = DebtObligation.validate_xbrl_rules(debt)
      assert valid
      assert errors == []
    end
  end
end
