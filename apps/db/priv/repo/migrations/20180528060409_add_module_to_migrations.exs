defmodule Innerpeace.Db.Repo.Migrations.AddModuleToMigrations do
  use Ecto.Migration

  def change do
    alter table(:migrations) do
      add :module, :string
    end
  end
end
