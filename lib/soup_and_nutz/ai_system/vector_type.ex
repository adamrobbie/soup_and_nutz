defmodule SoupAndNutz.AISystem.VectorType do
  @moduledoc """
  Custom Ecto type for pgvector vectors.
  """
  use Ecto.Type

  def type, do: :vector

  def cast(value) when is_list(value) do
    {:ok, value}
  end

  def cast(_), do: :error

  def load(value) when is_list(value) do
    {:ok, value}
  end

  def load(_), do: :error

  def dump(value) when is_list(value) do
    {:ok, value}
  end

  def dump(_), do: :error
end
