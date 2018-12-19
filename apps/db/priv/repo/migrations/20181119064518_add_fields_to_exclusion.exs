defmodule Innerpeace.Db.Repo.Migrations.AddFieldsToExclusion do
  use Ecto.Migration

  def change do
    alter table(:exclusions) do
      add :policy, {:array, :text}
      add :classification_type, :string
      add :type, :string
    end
  end
end
