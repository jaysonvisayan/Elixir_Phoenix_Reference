defmodule Innerpeace.Db.Repo.Migrations.AddBatchNumberToPayorProcedureUploadFile do
  use Ecto.Migration

  def change do
    alter table(:payor_procedure_upload_files) do
      add :batch_number, :string
      add :date_uploaded, :date
    end
  end
end
