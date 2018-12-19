defmodule Innerpeace.Db.Repo.Migrations.RemoveMemberProductId do
  use Ecto.Migration

  def change do
    alter table(:members) do
      remove (:product_code)
    end
  end
end
