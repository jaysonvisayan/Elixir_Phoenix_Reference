defmodule Innerpeace.Db.Repo.Migrations.CreateBatchFilesTable do
  use Ecto.Migration

  def change do
    create table(:batch_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :batch_id, references(:batches, type: :binary_id)
      add :file_id, references(:files, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)
      add :document_type, :string

      timestamps()
    end
  end
end
