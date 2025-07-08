defmodule SoupAndNutz.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :external_id, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:conversations, [:external_id])
  end
end
