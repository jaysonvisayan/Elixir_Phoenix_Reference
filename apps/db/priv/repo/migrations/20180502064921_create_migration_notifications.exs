defmodule Innerpeace.Db.Repo.Migrations.CreateMigrationNotifications do
  use Ecto.Migration

  def up do
    create table(:migration_notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :migration_id, references(:migrations, type: :binary_id, on_delete: :delete_all)
      add :is_success, :boolean
      add :details, :string

      timestamps()
    end
    create index(:migration_notifications, [:migration_id])
  end

  def down do
    drop table(:migration_notifications)
  end
end
