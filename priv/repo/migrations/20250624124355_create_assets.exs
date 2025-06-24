defmodule SoupAndNutz.Repo.Migrations.CreateAssets do
  use Ecto.Migration

  def change do
    create table(:assets) do
      # XBRL-inspired identifier fields
      add :asset_identifier, :string, null: false
      add :asset_name, :string, null: false
      add :asset_type, :string, null: false
      add :asset_category, :string
      
      # Financial measurement fields
      add :fair_value, :decimal, precision: 15, scale: 2
      add :book_value, :decimal, precision: 15, scale: 2
      add :currency_code, :string, null: false
      add :measurement_date, :date, null: false
      
      # XBRL context fields
      add :reporting_period, :string, null: false
      add :reporting_entity, :string, null: false
      add :reporting_scenario, :string
      
      # Additional metadata
      add :description, :text
      add :location, :string
      add :custodian, :string
      add :is_active, :boolean, default: true
      add :risk_level, :string
      add :liquidity_level, :string
      
      # XBRL validation fields
      add :validation_status, :string, default: "Pending"
      add :last_validated_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    # Create indexes for better performance
    create unique_index(:assets, [:asset_identifier])
    create index(:assets, [:asset_type])
    create index(:assets, [:reporting_entity])
    create index(:assets, [:reporting_period])
    create index(:assets, [:measurement_date])
    create index(:assets, [:currency_code])
    create index(:assets, [:is_active])
  end
end
