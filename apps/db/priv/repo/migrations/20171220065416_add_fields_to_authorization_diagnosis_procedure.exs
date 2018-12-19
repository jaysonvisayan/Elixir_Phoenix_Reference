defmodule Innerpeace.Db.Repo.Migrations.AddFieldsToAuthorizationDiagnosisProcedure do
  use Ecto.Migration

  def change do
    alter table(:authorization_procedure_diagnoses) do
      add :risk_share_type, :string
      add :risk_share_setup, :string
      add :risk_share_amount, :decimal
      add :percentage_covered, :decimal
      add :pec, :decimal
    end
  end
end
