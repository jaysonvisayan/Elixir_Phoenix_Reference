defmodule Innerpeace.Db.Repo.Migrations.AddStandardCptTypeInProcedureUploadLog do
  use Ecto.Migration

  def change do
    alter table(:procedure_upload_logs) do
      add :cpt_type, :string
    end
  end
end
