defmodule SoupAndNutz.Repo.Migrations.CreateEmbeddings do
  use Ecto.Migration

  def change do
        create table(:embeddings) do
      add :content, :text, null: false
      add :embedding_data, :text, null: false  # Store as JSON string
      add :embedding_vector, :vector, size: 1536  # pgvector column for similarity search
      add :metadata, :map, default: %{}
      add :user_id, references(:users, on_delete: :delete_all)
      add :conversation_id, references(:conversations, on_delete: :delete_all)
      add :message_id, references(:messages, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:embeddings, [:user_id])
    create index(:embeddings, [:conversation_id])
    create index(:embeddings, [:message_id])

    # Create a vector similarity index for fast similarity searches
    execute "CREATE INDEX ON embeddings USING ivfflat (embedding_vector vector_cosine_ops) WITH (lists = 100)"
  end
end
