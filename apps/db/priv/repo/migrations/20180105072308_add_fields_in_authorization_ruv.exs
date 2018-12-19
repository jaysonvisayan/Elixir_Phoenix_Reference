defmodule Innerpeace.Db.Repo.Migrations.AddFieldsInAuthorizationRuv do
  use Ecto.Migration

  def change do
    alter table(:authorization_ruvs) do
      add :risk_share_type, :string
      add :risk_share_setup, :string
      add :risk_share_amount, :decimal
      add :percentage_covered, :decimal
      add :pec, :decimal
      add :philhealth_pay, :decimal
    end
  end
end
