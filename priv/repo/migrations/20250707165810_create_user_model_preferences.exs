defmodule SoupAndNutz.Repo.Migrations.CreateUserModelPreferences do
  use Ecto.Migration

  def change do
    create table(:user_model_preferences) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :model_config, :jsonb, null: false
      add :is_active, :boolean, default: true, null: false
      add :last_used_at, :utc_datetime
      add :usage_count, :integer, default: 0, null: false

      timestamps()
    end

    create index(:user_model_preferences, [:user_id])
    create unique_index(:user_model_preferences, [:user_id, :is_active], where: "is_active = true")
  end
end
