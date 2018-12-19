defmodule Innerpeace.Db.Repo.Migrations.AddVatOnAuthorizationDiagnosis do
  use Ecto.Migration

  def change do
  	alter table(:authorization_diagnosis) do
      add :member_vat_amount, :decimal
      add :payor_vat_amount, :decimal
    end
  end
end
