defmodule Innerpeace.Db.Repo.Migrations.AddLimitsInExclusion do
  use Ecto.Migration

  def change do
    alter table(:exclusions) do
      add :limit_type, :string
      add :limit_percentage, :integer
      add :limit_amount, :decimal
    end
  end
end
