defmodule Innerpeace.Db.Repo.Migrations.CreateMigrationTbl do
  use Ecto.Migration

  def up do
    create table(:migrations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :is_fetch, :boolean

      timestamps()
    end
    create index(:migrations, [:user_id])
  end

  def down do
    drop table(:migrations)
  end

end
