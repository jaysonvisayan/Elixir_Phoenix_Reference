defmodule Innerpeace.Db.Repo.Migrations.AddFieldsOnAuthorizationProcedureDiagnosis do
  use Ecto.Migration

  def change do
    alter table(:authorization_procedure_diagnoses) do
      add :member_pay, :decimal
      add :payor_pay, :decimal
      add :product_benefit_id, references(:product_benefits, type: :binary_id)
    end
  end
end
