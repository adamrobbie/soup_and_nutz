defmodule SoupAndNutz.AISystem.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    field :external_id, :string
    has_many :messages, SoupAndNutz.AISystem.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:external_id])
    |> validate_required([:external_id])
    |> unique_constraint(:external_id)
  end
end
