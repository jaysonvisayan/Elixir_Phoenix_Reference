defmodule Innerpeace.Db.Repo.Migrations.ModifyMigrationNotificationTbl do
  use Ecto.Migration

  def up do
    alter table(:migration_notifications) do
      modify :details, :text
    end
  end

  def down do
    alter table(:migration_notifications) do
      modify :details, :string
    end
  end

end
