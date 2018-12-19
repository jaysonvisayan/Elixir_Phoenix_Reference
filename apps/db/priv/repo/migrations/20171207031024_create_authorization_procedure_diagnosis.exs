defmodule Innerpeace.Db.Repo.Migrations.CreateAuthorizationProcedureDiagnosis do
  use Ecto.Migration

  def change do
  	create table(:authorization_procedure_diagnoses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :authorization_id, references(:authorizations, type: :binary_id)
      add :payor_procedure_id, references(:payor_procedures, type: :binary_id)
      add :diagnosis_id, references(:diagnoses, type: :binary_id)
      add :unit, :decimal
      add :amount, :decimal
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

    timestamps()
    end

  end
end
