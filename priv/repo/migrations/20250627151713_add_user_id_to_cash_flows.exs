defmodule SoupAndNutz.Repo.Migrations.AddUserIdToCashFlows do
  use Ecto.Migration

  def up do
    # Step 1: Add user_id as nullable
    alter table(:cash_flows) do
      add :user_id, references(:users, on_delete: :delete_all), null: true
    end
    create index(:cash_flows, [:user_id])

    # Step 2: Backfill user_id with first user (if any rows exist)
    execute "UPDATE cash_flows SET user_id = (SELECT id FROM users LIMIT 1)"

    # Step 3: Set user_id as NOT NULL
    alter table(:cash_flows) do
      modify :user_id, :integer, null: false
    end
  end

  def down do
    alter table(:cash_flows) do
      remove :user_id
    end
  end
end
