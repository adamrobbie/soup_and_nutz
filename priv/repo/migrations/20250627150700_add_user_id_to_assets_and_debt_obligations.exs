defmodule SoupAndNutz.Repo.Migrations.AddUserIdToAssetsAndDebtObligations do
  use Ecto.Migration

  def up do
    # Step 1: Add user_id as nullable
    alter table(:assets) do
      add :user_id, references(:users, on_delete: :delete_all), null: true
    end
    create index(:assets, [:user_id])

    alter table(:debt_obligations) do
      add :user_id, references(:users, on_delete: :delete_all), null: true
    end
    create index(:debt_obligations, [:user_id])

    # Step 2: Backfill user_id with first user
    execute "UPDATE assets SET user_id = (SELECT id FROM users LIMIT 1)"
    execute "UPDATE debt_obligations SET user_id = (SELECT id FROM users LIMIT 1)"

    # Step 3: Set user_id as NOT NULL
    alter table(:assets) do
      modify :user_id, :integer, null: false
    end
    alter table(:debt_obligations) do
      modify :user_id, :integer, null: false
    end
  end

  def down do
    alter table(:assets) do
      remove :user_id
    end
    alter table(:debt_obligations) do
      remove :user_id
    end
  end
end
