defmodule Innerpeace.Db.Repo.Migrations.AddPayorAndMemberPortionOnAuthorizationDiagnosis do
  use Ecto.Migration

  def change do
  	alter table(:authorization_diagnosis) do
      add :payor_portion, :decimal
      add :member_portion, :decimal
    end
  end
end
