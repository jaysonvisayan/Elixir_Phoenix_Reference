defmodule Innerpeace.Db.Repo.Migrations.AddColumnAllDiagnosisAndAllProcedureToBenefitTable do
  use Ecto.Migration

  def change do
    alter table(:benefits) do
      add :all_diagnosis, :boolean, default: false
      add :all_procedure, :boolean, default: false
    end
  end
end
