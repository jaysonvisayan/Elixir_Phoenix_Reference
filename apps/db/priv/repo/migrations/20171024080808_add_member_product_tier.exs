defmodule Innerpeace.Db.Repo.Migrations.AddMemberProductTier do
  use Ecto.Migration

  def change do
    alter table(:member_products) do
      add :tier, :integer
    end
  end

end
