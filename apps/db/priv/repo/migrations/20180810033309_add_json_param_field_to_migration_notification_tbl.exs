defmodule Innerpeace.Db.Repo.Migrations.AddJsonParamFieldToMigrationNotificationTbl do
  use Ecto.Migration

  def up do
    alter table(:migration_notifications) do
      add :json_params, :jsonb
    end
  end

  def down do
    alter table(:migration_notifications) do
      remove :json_params
    end
  end
end
