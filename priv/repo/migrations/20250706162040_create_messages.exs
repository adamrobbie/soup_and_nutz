defmodule SoupAndNutz.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :role, :string
      add :content, :text
      add :conversation_id, references(:conversations, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:conversation_id])
  end
end
