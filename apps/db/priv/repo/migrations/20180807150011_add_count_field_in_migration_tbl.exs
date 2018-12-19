defmodule Innerpeace.Db.Repo.Migrations.AddCountFieldInMigrationTbl do
  use Ecto.Migration

  def up do
    alter table(:migrations) do
      add :count, :integer
    end
  end

  def down do
    alter table(:migrations) do
      remove :count
    end
  end
end
