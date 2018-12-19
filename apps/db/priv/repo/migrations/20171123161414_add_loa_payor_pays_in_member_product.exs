defmodule Innerpeace.Db.Repo.Migrations.AddLoaPayorPaysInMemberProduct do
  use Ecto.Migration

  def change do
    alter table(:member_products) do
      add :loa_payor_pays, :decimal
    end
  end
end
