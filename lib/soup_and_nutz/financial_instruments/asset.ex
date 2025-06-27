defmodule SoupAndNutz.FinancialInstruments.Asset do
  @moduledoc """
  Schema and business logic for assets in the financial instruments system.

  This module manages various types of financial assets including cash, investments,
  real estate, and other valuable holdings. It follows XBRL reporting standards
  for consistent financial data representation and validation.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias SoupAndNutz.XBRL.Concepts

  schema "assets" do
    # XBRL-inspired identifier fields
    field :asset_identifier, :string  # Unique identifier for the asset
    field :asset_name, :string       # Human-readable name
    field :asset_type, :string       # Classification from Concepts.asset_types
    field :asset_category, :string   # Sub-category within type

    # Financial measurement fields (following XBRL measurement concepts)
    field :fair_value, :decimal      # Current fair value
    field :book_value, :decimal      # Historical/book value
    field :currency_code, :string    # ISO currency code
    field :measurement_date, :date   # Date of measurement

    # XBRL context fields
    field :reporting_period, :string # e.g., "2024-12-31"
    field :reporting_entity, :string # Entity identifier
    field :reporting_scenario, :string # e.g., "Actual", "Budget", "Forecast"

    # Additional metadata
    field :description, :string
    field :location, :string         # Physical or logical location
    field :custodian, :string        # Who holds/manages the asset
    field :is_active, :boolean, default: true
    field :risk_level, :string       # Low, Medium, High
    field :liquidity_level, :string  # High, Medium, Low

    # XBRL validation fields
    field :validation_status, :string, default: "Pending" # Pending, Valid, Invalid
    field :last_validated_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [
      :asset_identifier, :asset_name, :asset_type, :asset_category,
      :fair_value, :book_value, :currency_code, :measurement_date,
      :reporting_period, :reporting_entity, :reporting_scenario,
      :description, :location, :custodian, :is_active,
      :risk_level, :liquidity_level, :validation_status, :last_validated_at
    ])
    |> validate_required([
      :asset_identifier, :asset_name, :asset_type, :currency_code,
      :measurement_date, :reporting_period, :reporting_entity
    ])
    |> validate_inclusion(:asset_type, Concepts.asset_types())
    |> validate_inclusion(:currency_code, Concepts.currency_codes())
    |> validate_inclusion(:risk_level, Concepts.risk_levels())
    |> validate_inclusion(:liquidity_level, Concepts.liquidity_levels())
    |> validate_inclusion(:validation_status, Concepts.validation_statuses())
    |> validate_number(:fair_value, greater_than_or_equal_to: 0)
    |> validate_number(:book_value, greater_than_or_equal_to: 0)
    |> unique_constraint(:asset_identifier)
    |> validate_format(:asset_identifier, ~r/^[A-Z0-9_-]+$/, message: "must contain only uppercase letters, numbers, underscores, and hyphens")
  end

  @doc """
  Returns a list of valid asset types for form selection.
  """
  def asset_types, do: Concepts.asset_types()

  @doc """
  Returns a list of valid currency codes for form selection.
  """
  def currency_codes, do: Concepts.currency_codes()

  @doc """
  Calculates the total fair value of assets in a given currency.
  """
  def total_fair_value(assets, currency \\ "USD") do
    assets
    |> Enum.filter(&(&1.currency_code == currency))
    |> Enum.reduce(Decimal.new(0), fn asset, acc ->
      Decimal.add(acc, asset.fair_value || Decimal.new(0))
    end)
  end

  @doc """
  Validates asset data according to XBRL business rules.
  """
  def validate_xbrl_rules(asset) do
    errors = []

    errors = if asset.fair_value && asset.book_value do
      difference = Decimal.abs(Decimal.sub(asset.fair_value, asset.book_value))
      threshold = Decimal.mult(asset.book_value, Decimal.new("0.1")) # 10% threshold

      if Decimal.gt?(difference, threshold) do
        [{"fair_value", "Significant difference from book value requires explanation"} | errors]
      else
        errors
      end
    else
      errors
    end

    errors = if asset.measurement_date && Date.compare(asset.measurement_date, Date.utc_today()) == :gt do
      [{"measurement_date", "Measurement date cannot be in the future"} | errors]
    else
      errors
    end

    {Enum.empty?(errors), errors}
  end
end
