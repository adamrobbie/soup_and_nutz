defmodule SoupAndNutzWeb.FinancialHelpers do
  @moduledoc """
  Helper functions for financial formatting and display in the web interface.
  """

  @doc """
  Formats a decimal amount as currency with proper symbol and formatting.

  ## Examples
      iex> format_currency(Decimal.new("1234.56"), :USD)
      "$1,234.56"

      iex> format_currency(Decimal.new("1234.56"), :EUR)
      "€1,234.56"

      iex> format_currency(Decimal.new("0"), :USD)
      "$0.00"
  """
  def format_currency(amount, currency \\ :USD)

  def format_currency(amount, currency) when is_struct(amount, Decimal) do
    amount
    |> Decimal.to_float()
    |> then(fn float_amount -> trunc(float_amount * 100) end)
    |> Money.new(currency)
    |> Money.to_string()
  end

  def format_currency(amount, currency) when is_float(amount) do
    amount
    |> then(fn float_amount -> trunc(float_amount * 100) end)
    |> Money.new(currency)
    |> Money.to_string()
  end

  def format_currency(amount, currency) when is_integer(amount) do
    amount
    |> Money.new(currency)
    |> Money.to_string()
  end

  def format_currency(nil, currency) do
    Money.new(0, currency) |> Money.to_string()
  end

  @doc """
  Formats a decimal amount as currency without the currency symbol.

  ## Examples
      iex> format_amount(Decimal.new("1234.56"))
      "1,234.56"
  """
  def format_amount(amount) when is_struct(amount, Decimal) do
    amount
    |> Decimal.to_string()
    |> format_number_with_commas()
  end

  @doc """
  Formats a percentage value with proper decimal places.

  ## Examples
      iex> format_percentage(Decimal.new("0.1234"))
      "12.34%"

      iex> format_percentage(Decimal.new("1.5"))
      "150.00%"
  """
  def format_percentage(amount) when is_struct(amount, Decimal) do
    amount
    |> Decimal.mult(Decimal.new("100"))
    |> Decimal.round(2)
    |> Decimal.to_string()
    |> Kernel.<>("%")
  end

  def format_percentage(amount) when is_float(amount) do
    amount
    |> Decimal.new()
    |> format_percentage()
  end

  def format_percentage(nil), do: "0.00%"

  @doc """
  Formats a number with commas for thousands separators.

  ## Examples
      iex> format_number_with_commas("1234567.89")
      "1,234,567.89"

      iex> format_number_with_commas("1000")
      "1,000"
  """
  def format_number_with_commas(number_string) when is_binary(number_string) do
    case String.split(number_string, ".") do
      [whole_part, decimal_part] ->
        whole_part
        |> String.graphemes()
        |> Enum.reverse()
        |> Enum.chunk_every(3)
        |> Enum.map(&Enum.reverse/1)
        |> Enum.reverse()
        |> Enum.join(",")
        |> Kernel.<>(".#{decimal_part}")

      [whole_part] ->
        whole_part
        |> String.graphemes()
        |> Enum.reverse()
        |> Enum.chunk_every(3)
        |> Enum.map(&Enum.reverse/1)
        |> Enum.reverse()
        |> Enum.join(",")
    end
  end

  @doc """
  Formats currency amounts in a compact way (e.g., $1.2K, $1.5M).

  ## Examples
      iex> format_compact_currency(Decimal.new("1500"), :USD)
      "$1.5K"

      iex> format_compact_currency(Decimal.new("1500000"), :USD)
      "$1.5M"
  """
  def format_compact_currency(amount, currency \\ :USD)

  def format_compact_currency(amount, currency) when is_struct(amount, Decimal) do
    amount_float = Decimal.to_float(amount)

    cond do
      amount_float >= 1_000_000 ->
        "#{format_currency(amount_float / 1_000_000, currency)}M"
      amount_float >= 1_000 ->
        "#{format_currency(amount_float / 1_000, currency)}K"
      true ->
        format_currency(amount, currency)
    end
  end

  def format_compact_currency(amount, currency) when is_float(amount) do
    amount
    |> Decimal.new()
    |> format_compact_currency(currency)
  end

  @doc """
  Formats a change amount with color-coded indicators.
  Returns a tuple with the formatted string and CSS class.

  ## Examples
      iex> format_change(Decimal.new("123.45"), :USD)
      {"+$123.45", "text-green-600"}

      iex> format_change(Decimal.new("-123.45"), :USD)
      {"-$123.45", "text-red-600"}
  """
  def format_change(amount, currency \\ :USD)

  def format_change(amount, currency) when is_struct(amount, Decimal) do
    formatted = format_currency(amount, currency)
    class = if Decimal.gt?(amount, Decimal.new("0")), do: "text-green-600 dark:text-green-400", else: "text-red-600 dark:text-red-400"
    {formatted, class}
  end

  def format_change(amount, currency) when is_float(amount) do
    amount
    |> Decimal.new()
    |> format_change(currency)
  end

  def format_change(nil, currency) do
    {format_currency(0, currency), "text-gray-600 dark:text-gray-400"}
  end

  @doc """
  Formats a percentage change with color-coded indicators.
  Returns a tuple with the formatted string and CSS class.

  ## Examples
      iex> format_percentage_change(Decimal.new("0.1234"))
      {"+12.34%", "text-green-600"}

      iex> format_percentage_change(Decimal.new("-0.1234"))
      {"-12.34%", "text-red-600"}
  """
  def format_percentage_change(amount) when is_struct(amount, Decimal) do
    case Decimal.compare(amount, Decimal.new("0")) do
      :gt ->
        {"+#{format_percentage(amount)}", "text-green-600 dark:text-green-400"}

      :lt ->
        {"-#{format_percentage(Decimal.abs(amount))}", "text-red-600 dark:text-red-400"}

      :eq ->
        {format_percentage(amount), "text-gray-600 dark:text-gray-400"}
    end
  end

  @doc """
  Formats a risk level with appropriate styling.
  Returns a tuple with the formatted string and CSS class.

  ## Examples
      iex> format_risk_level("High")
      {"High", "text-red-600 bg-red-100"}

      iex> format_risk_level("Low")
      {"Low", "text-green-600 bg-green-100"}
  """
  def format_risk_level(risk_level) when is_binary(risk_level) do
    case String.downcase(risk_level) do
      "high" ->
        {"High", "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"}

      "medium" ->
        {"Medium", "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300"}

      "low" ->
        {"Low", "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"}

      _ ->
        {risk_level, "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300"}
    end
  end

  @doc """
  Formats a liquidity level with appropriate styling.
  Returns a tuple with the formatted string and CSS class.
  """
  def format_liquidity_level(liquidity_level) when is_binary(liquidity_level) do
    case String.downcase(liquidity_level) do
      "high" ->
        {"High", "text-green-600 dark:text-green-400 bg-green-100 dark:bg-green-900/20"}

      "medium" ->
        {"Medium", "text-yellow-600 dark:text-yellow-400 bg-yellow-100 dark:bg-yellow-900/20"}

      "low" ->
        {"Low", "text-red-600 dark:text-red-400 bg-red-100 dark:bg-red-900/20"}

      _ ->
        {liquidity_level, "text-gray-600 dark:text-gray-400 bg-gray-100 dark:bg-gray-800"}
    end
  end

  # Private helper for compact formatting
  defp format_compact_amount(amount, currency, suffix) do
    currency_symbol = get_currency_symbol(currency)
    formatted_amount = :erlang.float_to_binary(amount, [decimals: 1])
    "#{currency_symbol}#{formatted_amount}#{suffix}"
  end

  # Private helper to get currency symbols
  defp get_currency_symbol(:USD), do: "$"
  defp get_currency_symbol(:EUR), do: "€"
  defp get_currency_symbol(:GBP), do: "£"
  defp get_currency_symbol(:JPY), do: "¥"
  defp get_currency_symbol(:CAD), do: "C$"
  defp get_currency_symbol(_), do: ""
end
