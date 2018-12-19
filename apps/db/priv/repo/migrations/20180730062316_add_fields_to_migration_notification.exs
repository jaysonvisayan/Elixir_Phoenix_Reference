defmodule Innerpeace.Db.Repo.Migrations.AddFieldsToMigrationNotification do
  use Ecto.Migration

  def change do
    alter table(:migration_notifications) do
      add :result, :string
    end
  end
end
