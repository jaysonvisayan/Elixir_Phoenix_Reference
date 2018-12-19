defmodule Innerpeace.Db.Repo.Migrations.AddFieldsOnAuthorizationDiagnosis do
  use Ecto.Migration

  def change do
  	alter table(:authorization_diagnosis) do
      add :vat_amount, :decimal
      add :special_approval_amount, :decimal
      add :member_excess, :decimal
      add :member_not_excess, :decimal
      add :total_amount_vatable, :decimal
      add :total_amount, :decimal
    end
  end
end
