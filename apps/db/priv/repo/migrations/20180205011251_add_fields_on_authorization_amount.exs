defmodule Innerpeace.Db.Repo.Migrations.AddFieldsOnAuthorizationAmount do
  use Ecto.Migration

  def change do
  	alter table(:authorization_amounts) do
      add :vat_amount, :decimal
      add :special_approval_amount, :decimal
      add :member_excess, :decimal
      add :member_not_excess, :decimal
      add :total_amount_vatable, :decimal
    end
  end
end
