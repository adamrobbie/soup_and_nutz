defmodule SoupAndNutz.Repo.Migrations.CreateConversationMemories do
  use Ecto.Migration

  def change do
    create table(:conversation_memories) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :conversation_id, :string
      add :message, :string
      add :response, :string
      add :extracted_data, :map
      add :confidence, :float
      add :action_taken, :string
      add :context_summary, :string
      add :entities, :map
      timestamps(type: :utc_datetime)
    end
    create index(:conversation_memories, [:user_id])
    create index(:conversation_memories, [:conversation_id])
  end
end
