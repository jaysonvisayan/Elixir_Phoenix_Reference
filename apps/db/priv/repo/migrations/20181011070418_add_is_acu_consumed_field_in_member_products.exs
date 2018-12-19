defmodule Innerpeace.Db.Repo.Migrations.AddIsAcuConsumedFieldInMemberProducts do
  use Ecto.Migration

  def change do
    alter table(:member_products) do
      add :is_acu_consumed, :boolean, default: false
    end
  end
end
