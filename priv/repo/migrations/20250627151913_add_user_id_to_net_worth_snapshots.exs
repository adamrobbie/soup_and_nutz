defmodule SoupAndNutz.Repo.Migrations.AddUserIdToNetWorthSnapshots do
  use Ecto.Migration

  def up do
    # Step 1: Add user_id as nullable
    alter table(:net_worth_snapshots) do
      add :user_id, references(:users, on_delete: :delete_all), null: true
    end
    create index(:net_worth_snapshots, [:user_id])

    # Step 2: Backfill user_id with first user (if any rows exist)
    execute "UPDATE net_worth_snapshots SET user_id = (SELECT id FROM users LIMIT 1)"

    # Step 3: Set user_id as NOT NULL
    alter table(:net_worth_snapshots) do
      modify :user_id, :integer, null: false
    end
  end

  def down do
    alter table(:net_worth_snapshots) do
      remove :user_id
    end
  end
end
