defmodule Innerpeace.Db.Repo.Migrations.CreateMigrationExtractedResultLogsTbl do
  use Ecto.Migration

  def up do
    create table(:migration_extracted_result_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :module, :string
      add :status_code, :string
      add :migration_id, references(:migrations, type: :binary_id, on_delete: :delete_all)
      add :remarks, :string

      timestamps()
    end
    create index(:migration_extracted_result_logs, [:migration_id])
  end

  def down do
    drop table(:migration_extracted_result_logs)
  end

end
