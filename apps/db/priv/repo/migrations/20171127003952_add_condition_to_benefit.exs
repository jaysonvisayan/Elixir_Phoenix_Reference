defmodule Innerpeace.Db.Repo.Migrations.AddConditionToBenefit do
  use Ecto.Migration

  def change do
    alter table(:benefits) do
      add :condition, :string
    end
  end
end
