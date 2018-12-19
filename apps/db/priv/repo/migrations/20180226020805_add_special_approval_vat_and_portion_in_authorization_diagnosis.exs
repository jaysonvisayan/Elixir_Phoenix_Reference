defmodule Innerpeace.Db.Repo.Migrations.AddSpecialApprovalVatAndPortionInAuthorizationDiagnosis do
  use Ecto.Migration

  def change do
  	alter table(:authorization_diagnosis) do
      add :special_approval_portion, :decimal
      add :special_approval_vat_amount, :decimal
    end
  end
end
