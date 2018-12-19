defmodule Innerpeace.Db.Repo.Migrations.RenameIsSuccessToIsDoneInMigrationTbl do
  use Ecto.Migration

  def up do
    rename table("migrations"), :is_fetch, to: :is_done
    alter table(:migration_notifications) do
      add :is_fetch, :boolean
    end
  end

  def down do
    rename table("migrations"), :is_done, to: :is_fetch
    alter table(:migration_notifications) do
      remove :is_fetch
    end
  end

end
