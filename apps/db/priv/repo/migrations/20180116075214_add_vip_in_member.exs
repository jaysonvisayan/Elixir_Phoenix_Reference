defmodule Innerpeace.Db.Repo.Migrations.AddVipInMember do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :vip, :boolean, default: false
    end
  end
end
