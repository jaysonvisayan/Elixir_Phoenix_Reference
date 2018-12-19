defmodule Innerpeace.Db.Repo.Migrations.AlterTableProductsAddFundingArrangementAndFeeForServiceField do
  use Ecto.Migration

  def up do
    alter table(:products) do
      add :funding_arrangement, :string
      add :fee_for_service, :boolean, default: false
    end
  end
  def down do
    alter table(:products) do
      remove :funding_arrangement
      remove :fee_for_service
    end
  end
end
