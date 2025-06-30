defmodule SoupAndNutz.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      # Authentication fields
      add :email, :string, null: false
      add :username, :string, null: false
      add :password_hash, :string, null: false
      add :is_active, :boolean, default: true, null: false
      add :email_verified_at, :utc_datetime
      add :last_login_at, :utc_datetime

      # Profile information
      add :first_name, :string
      add :last_name, :string
      add :date_of_birth, :date
      add :phone_number, :string
      add :timezone, :string, default: "UTC"
      add :locale, :string, default: "en"

      # Financial preferences and settings
      add :preferred_currency, :string, default: "USD", null: false
      add :default_reporting_period, :string, default: "Monthly"
      add :financial_year_start, :date
      add :tax_year_end, :date
      add :risk_tolerance, :string, default: "Medium"  # Low, Medium, High
      add :investment_horizon, :string, default: "LongTerm"  # ShortTerm, MediumTerm, LongTerm

      # Privacy and data settings
      add :data_sharing_preferences, :map, default: %{}
      add :notification_preferences, :map, default: %{}
      add :privacy_level, :string, default: "Private"  # Public, Private, Shared

      # Account management
      add :account_type, :string, default: "Individual"  # Individual, Family, Business
      add :subscription_tier, :string, default: "Free"  # Free, Basic, Premium, Enterprise
      add :subscription_expires_at, :utc_datetime

      # Metadata
      add :created_by, :string  # For admin-created accounts
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    # Create indexes for better performance
    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
    create index(:users, [:is_active])
    create index(:users, [:account_type])
    create index(:users, [:subscription_tier])
    create index(:users, [:preferred_currency])
    create index(:users, [:risk_tolerance])
    create index(:users, [:inserted_at])
  end
end
