defmodule Innerpeace.Db.Repo.Migrations.AlterAuthorizationDiagnosisFields do
  use Ecto.Migration

  def change do
  	alter table(:authorization_diagnosis) do
      remove :member_not_excess
      remove :member_excess
      remove :total_amount_vatable

      add :pre_existing_amount, :decimal
    end

    alter table(:authorization_amounts) do
      remove :member_not_excess
      remove :member_excess
      remove :total_amount_vatable

      add :pre_existing_amount, :decimal
    end
  end
end
