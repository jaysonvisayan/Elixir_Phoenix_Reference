defmodule Innerpeace.Db.Repo.Migrations.AlterProductsTable do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :product_category, :string
    end

  end
end
