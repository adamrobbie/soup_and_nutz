defmodule SoupAndNutz.Accounts.UserModelPreference do
  @moduledoc """
  Schema for storing user model preferences.

  This allows users to save their preferred AI model configurations
  and switch between different providers (OpenAI, Anthropic, Ollama, etc.)
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias SoupAndNutz.Accounts.User

  schema "user_model_preferences" do
    field :model_config, :map, default: %{}
    field :is_active, :boolean, default: true
    field :last_used_at, :utc_datetime
    field :usage_count, :integer, default: 0

    belongs_to :user, User

    timestamps()
  end

  @doc """
  Changeset for creating or updating user model preferences.
  """
  def changeset(user_model_preference, attrs) do
    user_model_preference
    |> cast(attrs, [:user_id, :model_config, :is_active, :last_used_at, :usage_count])
    |> validate_required([:user_id, :model_config])
    |> validate_model_config()
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id, name: :user_model_preferences_user_id_index, where: "is_active = true")
  end

  @doc """
  Changeset for updating usage statistics.
  """
  def usage_changeset(user_model_preference, attrs) do
    user_model_preference
    |> cast(attrs, [:last_used_at, :usage_count])
    |> validate_required([:last_used_at, :usage_count])
  end

  defp validate_model_config(changeset) do
    validate_change(changeset, :model_config, fn :model_config, model_config ->
      cond do
        not is_map(model_config) ->
          [model_config: "must be a map"]
        is_nil(model_config.provider) ->
          [model_config: "provider is required"]
        is_nil(model_config.model) ->
          [model_config: "model is required"]
        not is_atom(model_config.provider) ->
          [model_config: "provider must be an atom"]
        not is_binary(model_config.model) ->
          [model_config: "model must be a string"]
        not valid_provider?(model_config.provider) ->
          [model_config: "invalid provider: #{model_config.provider}"]
        true ->
          []
      end
    end)
  end

  defp valid_provider?(provider) do
    provider in [:openai, :anthropic, :ollama, :local]
  end

  @doc """
  Get the active model preference for a user.
  """
  def get_active_by_user_id(user_id) do
    from(p in __MODULE__,
      where: p.user_id == ^user_id and p.is_active == true,
      limit: 1
    )
    |> SoupAndNutz.Repo.one()
  end

  @doc """
  Get all model preferences for a user.
  """
  def get_by_user_id(user_id) do
    from(p in __MODULE__,
      where: p.user_id == ^user_id,
      order_by: [desc: p.updated_at]
    )
    |> SoupAndNutz.Repo.all()
  end

  @doc """
  Create or update the active model preference for a user.
  """
  def create_or_update_active(user_id, model_config) do
    # First, deactivate any existing active preferences
    from(p in __MODULE__,
      where: p.user_id == ^user_id and p.is_active == true
    )
    |> SoupAndNutz.Repo.update_all(set: [is_active: false])

    # Then create or update the new preference
    case get_active_by_user_id(user_id) do
      nil ->
        # Create new preference
        %__MODULE__{}
        |> changeset(%{
          user_id: user_id,
          model_config: model_config,
          is_active: true,
          last_used_at: DateTime.utc_now(),
          usage_count: 1
        })
        |> SoupAndNutz.Repo.insert()

      existing ->
        # Update existing preference
        existing
        |> changeset(%{
          model_config: model_config,
          is_active: true,
          last_used_at: DateTime.utc_now(),
          usage_count: existing.usage_count + 1
        })
        |> SoupAndNutz.Repo.update()
    end
  end

  @doc """
  Increment usage count for a model preference.
  """
  def increment_usage(user_model_preference) do
    user_model_preference
    |> usage_changeset(%{
      last_used_at: DateTime.utc_now(),
      usage_count: user_model_preference.usage_count + 1
    })
    |> SoupAndNutz.Repo.update()
  end

  @doc """
  Get model usage statistics for a user.
  """
  def get_usage_stats(user_id) do
    from(p in __MODULE__,
      where: p.user_id == ^user_id,
      select: %{
        provider: fragment("model_config->>'provider'"),
        model: fragment("model_config->>'model'"),
        usage_count: p.usage_count,
        last_used_at: p.last_used_at,
        is_active: p.is_active
      },
      order_by: [desc: p.usage_count]
    )
    |> SoupAndNutz.Repo.all()
  end

  @doc """
  Get popular models across all users.
  """
  def get_popular_models(limit \\ 10) do
    from(p in __MODULE__,
      select: %{
        provider: fragment("model_config->>'provider'"),
        model: fragment("model_config->>'model'"),
        total_usage: sum(p.usage_count),
        user_count: count(p.user_id)
      },
      group_by: [fragment("model_config->>'provider'"), fragment("model_config->>'model'")],
      order_by: [desc: sum(p.usage_count)],
      limit: ^limit
    )
    |> SoupAndNutz.Repo.all()
  end
end
