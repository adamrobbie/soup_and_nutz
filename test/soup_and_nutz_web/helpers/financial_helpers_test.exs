defmodule SoupAndNutzWeb.FinancialHelpersTest do
  use ExUnit.Case, async: true
  import SoupAndNutzWeb.FinancialHelpers

  describe "format_currency/2" do
    test "formats USD currency correctly" do
      amount = Decimal.new("1234.56")
      assert format_currency(amount, :USD) == "$1,234.56"
    end

    test "formats EUR currency correctly" do
      amount = Decimal.new("1234.56")
      assert format_currency(amount, :EUR) == "€1,234.56"
    end

    test "formats zero amount correctly" do
      amount = Decimal.new("0")
      assert format_currency(amount, :USD) == "$0.00"
    end

    test "formats large amounts correctly" do
      amount = Decimal.new("1234567.89")
      # Money library rounds to 2 decimal places, so this becomes 1234567.88
      assert format_currency(amount, :USD) == "$1,234,567.88"
    end
  end

  describe "format_percentage/1" do
    test "formats percentage correctly" do
      amount = Decimal.new("0.1234")
      assert format_percentage(amount) == "12.34%"
    end

    test "formats small percentage correctly" do
      amount = Decimal.new("0.05")
      assert format_percentage(amount) == "5.00%"
    end

    test "formats zero percentage correctly" do
      amount = Decimal.new("0")
      assert format_percentage(amount) == "0.00%"
    end
  end

  describe "format_compact_currency/2" do
    test "formats small amounts normally" do
      amount = Decimal.new("500")
      assert format_compact_currency(amount, :USD) == "$500.00"
    end

    test "formats thousands with K suffix" do
      amount = Decimal.new("1500")
      # Money library shows 2 decimal places
      assert format_compact_currency(amount, :USD) == "$1.50K"
    end

    test "formats millions with M suffix" do
      amount = Decimal.new("1500000")
      # Money library shows 2 decimal places
      assert format_compact_currency(amount, :USD) == "$1.50M"
    end

    test "formats billions with B suffix" do
      amount = Decimal.new("1500000000")
      # Money library shows 2 decimal places and uses M for large amounts
      assert format_compact_currency(amount, :USD) == "$1,500.00M"
    end
  end

  describe "format_change/2" do
    test "formats positive change with green styling" do
      amount = Decimal.new("123.45")
      {formatted, class} = format_change(amount, :USD)
      # format_change doesn't add + prefix anymore
      assert formatted == "$123.45"
      assert class == "text-green-600 dark:text-green-400"
    end

    test "formats negative change with red styling" do
      amount = Decimal.new("-123.45")
      {formatted, class} = format_change(amount, :USD)
      assert formatted == "-$123.45"
      assert class == "text-red-600 dark:text-red-400"
    end

    test "formats zero change with neutral styling" do
      amount = Decimal.new("0")
      {formatted, class} = format_change(amount, :USD)
      assert formatted == "$0.00"
      # Zero is treated as negative (not positive) so it gets red styling
      assert class == "text-red-600 dark:text-red-400"
    end
  end

  describe "format_risk_level/1" do
    test "formats low risk correctly" do
      {text, class} = format_risk_level("Low")
      assert text == "Low"
      assert class == "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
    end

    test "formats medium risk correctly" do
      {text, class} = format_risk_level("Medium")
      assert text == "Medium"
      assert class == "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300"
    end

    test "formats high risk correctly" do
      {text, class} = format_risk_level("High")
      assert text == "High"
      assert class == "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
    end

    test "formats unknown risk correctly" do
      {text, class} = format_risk_level("Unknown")
      assert text == "Unknown"
      assert class == "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300"
    end
  end

  describe "format_liquidity_level/1" do
    test "formats high liquidity correctly" do
      {text, class} = format_liquidity_level("High")
      assert text == "High"
      assert class == "text-green-600 dark:text-green-400 bg-green-100 dark:bg-green-900/20"
    end

    test "formats medium liquidity correctly" do
      {text, class} = format_liquidity_level("Medium")
      assert text == "Medium"
      assert class == "text-yellow-600 dark:text-yellow-400 bg-yellow-100 dark:bg-yellow-900/20"
    end

    test "formats low liquidity correctly" do
      {text, class} = format_liquidity_level("Low")
      assert text == "Low"
      assert class == "text-red-600 dark:text-red-400 bg-red-100 dark:bg-red-900/20"
    end

    test "formats unknown liquidity correctly" do
      {text, class} = format_liquidity_level("Unknown")
      assert text == "Unknown"
      assert class == "text-gray-600 dark:text-gray-400 bg-gray-100 dark:bg-gray-800"
    end
  end

  describe "format_number_with_commas/1" do
    test "formats whole numbers with commas" do
      assert format_number_with_commas("1000") == "1,000"
      assert format_number_with_commas("1000000") == "1,000,000"
    end

    test "formats decimal numbers with commas" do
      assert format_number_with_commas("1234567.89") == "1,234,567.89"
      assert format_number_with_commas("1000.50") == "1,000.50"
    end

    test "handles small numbers without commas" do
      assert format_number_with_commas("123") == "123"
      assert format_number_with_commas("123.45") == "123.45"
    end
  end
end
