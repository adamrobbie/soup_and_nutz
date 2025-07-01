defmodule SoupAndNutz.Repo.Migrations.AddVectorToAssetsAndDebtObligations do
  use Ecto.Migration

  def change do
    alter table(:assets) do
      add :embedding, :vector, size: 1536
    end

    alter table(:debt_obligations) do
      add :embedding, :vector, size: 1536
    end
  end
end
