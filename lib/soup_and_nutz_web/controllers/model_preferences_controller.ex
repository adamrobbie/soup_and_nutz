defmodule SoupAndNutzWeb.ModelPreferencesController do
  use SoupAndNutzWeb, :controller

  alias SoupAndNutz.AISystem.ModelProvider
  alias SoupAndNutz.Accounts.UserModelPreference

  def index(conn, _params) do
    user_id = get_session(conn, :user_id)

    if user_id do
      available_models = ModelProvider.get_available_models()
      current_preference = UserModelPreference.get_active_by_user_id(user_id)
      usage_stats = UserModelPreference.get_usage_stats(user_id)

      render(conn, :index, %{
        available_models: available_models,
        current_preference: current_preference,
        usage_stats: usage_stats
      })
    else
      redirect(conn, to: ~p"/auth/login")
    end
  end

  def set_model(conn, %{"model_config" => model_config}) do
    user_id = get_session(conn, :user_id)

    if user_id do
      # Convert string keys to atoms for provider
      config = %{
        provider: String.to_existing_atom(model_config["provider"]),
        model: model_config["model"],
        temperature: parse_float(model_config["temperature"]),
        max_tokens: parse_integer(model_config["max_tokens"]),
        timeout: parse_integer(model_config["timeout"]),
        base_url: model_config["base_url"],
        api_key: model_config["api_key"]
      }

      case ModelProvider.set_user_model(user_id, config) do
        {:ok, _preference} ->
          conn
          |> put_flash(:info, "Model preference updated successfully!")
          |> redirect(to: ~p"/model-preferences")

        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to update model preference: #{reason}")
          |> redirect(to: ~p"/model-preferences")
      end
    else
      redirect(conn, to: ~p"/auth/login")
    end
  end

  def test_model(conn, %{"model_config" => model_config}) do
    user_id = get_session(conn, :user_id)

    if user_id do
      # Convert string keys to atoms for provider
      config = %{
        provider: String.to_existing_atom(model_config["provider"]),
        model: model_config["model"],
        temperature: parse_float(model_config["temperature"]),
        max_tokens: parse_integer(model_config["max_tokens"]),
        timeout: parse_integer(model_config["timeout"]),
        base_url: model_config["base_url"],
        api_key: model_config["api_key"]
      }

      case ModelProvider.test_model(config) do
        {:ok, test_result} ->
          json(conn, %{
            success: true,
            result: test_result
          })

        {:error, reason} ->
          json(conn, %{
            success: false,
            error: reason
          })
      end
    else
      json(conn, %{
        success: false,
        error: "User not authenticated"
      })
    end
  end

  def get_stats(conn, _params) do
    user_id = get_session(conn, :user_id)

    if user_id do
      usage_stats = UserModelPreference.get_usage_stats(user_id)
      popular_models = UserModelPreference.get_popular_models(5)

      json(conn, %{
        usage_stats: usage_stats,
        popular_models: popular_models
      })
    else
      json(conn, %{
        error: "User not authenticated"
      })
    end
  end

  defp parse_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> nil
    end
  end
  defp parse_float(_), do: nil

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end
  defp parse_integer(_), do: nil
end
