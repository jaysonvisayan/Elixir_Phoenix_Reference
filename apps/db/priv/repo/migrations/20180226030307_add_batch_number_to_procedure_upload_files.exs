defmodule Innerpeace.Db.Repo.Migrations.AddBatchNumberToProcedureUploadFiles do
  use Ecto.Migration

  def change do
    alter table(:procedure_upload_files) do
      add :batch_number, :string
      add :date_uploaded, :date
    end
  end
end
