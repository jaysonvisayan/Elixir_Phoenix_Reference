defmodule Innerpeace.Db.Repo.Migrations.RenameFundingArrangementToPemeFundingArrangementInProductTbl do
  use Ecto.Migration

  def up do
    rename table("products"), :funding_arrangement, to: :peme_funding_arrangement
    rename table("products"), :fee_for_service, to: :peme_fee_for_service
  end

  def down do
    rename table("products"), :peme_funding_arrangement, to: :funding_arrangement
    rename table("products"), :peme_fee_for_service, to: :fee_for_service
  end
end
