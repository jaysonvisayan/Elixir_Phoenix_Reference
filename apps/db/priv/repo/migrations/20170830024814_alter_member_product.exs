defmodule Innerpeace.Db.Repo.Migrations.AlterMemberProduct do
  use Ecto.Migration

  def change do
    alter table(:member_products) do
      remove (:product_code)
      add :account_product_id, references(:account_products, type: :binary_id)
    end
    create unique_index(:member_products, [:member_id, :account_product_id])
  end
end
