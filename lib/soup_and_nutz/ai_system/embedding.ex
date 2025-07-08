defmodule SoupAndNutz.AISystem.Embedding do
  use Ecto.Schema
  import Ecto.Changeset

      schema "embeddings" do
    field :content, :string
    field :embedding_data, :string  # Store as JSON string
    field :metadata, :map, default: %{}

    belongs_to :user, SoupAndNutz.Accounts.User
    belongs_to :conversation, SoupAndNutz.AISystem.Conversation
    belongs_to :message, SoupAndNutz.AISystem.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(embedding, attrs) do
    embedding
    |> cast(attrs, [:content, :embedding_data, :metadata, :user_id, :conversation_id, :message_id])
    |> validate_required([:content, :embedding_data])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:message_id)
  end
end
