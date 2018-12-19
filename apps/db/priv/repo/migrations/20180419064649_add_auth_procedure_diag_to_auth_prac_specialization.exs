defmodule Innerpeace.Db.Repo.Migrations.AddAuthProcedureDiagToAuthPracSpecialization do
  use Ecto.Migration

  def up do
    alter table(:authorization_procedure_diagnoses) do
      add :authorization_practitioner_specialization_id, references(:authorization_practitioner_specializations, type: :binary_id, on_delete: :delete_all)
    end
  end

  def down do
    alter table(:authorization_procedure_diagnoses) do
      remove :authorization_practitioner_specialization_id
    end
  end
end
