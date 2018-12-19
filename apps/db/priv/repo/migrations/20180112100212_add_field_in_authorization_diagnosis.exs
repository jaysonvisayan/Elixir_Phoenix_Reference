defmodule Innerpeace.Db.Repo.Migrations.AddFieldInAuthorizationDiagnosis do
  use Ecto.Migration

  def change do
    alter table(:authorization_diagnosis) do
      add :member_pay, :decimal
      add :payor_pay, :decimal
    end
  end
end
