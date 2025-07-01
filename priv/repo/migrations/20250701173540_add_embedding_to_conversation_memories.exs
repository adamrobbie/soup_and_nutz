defmodule SoupAndNutz.Repo.Migrations.AddEmbeddingToConversationMemories do
  use Ecto.Migration

  def change do
    alter table(:conversation_memories) do
      add :embedding, {:array, :float}
    end

    # Create an index for vector similarity search
    create index(:conversation_memories, [:embedding], using: :gin)
  end
end
