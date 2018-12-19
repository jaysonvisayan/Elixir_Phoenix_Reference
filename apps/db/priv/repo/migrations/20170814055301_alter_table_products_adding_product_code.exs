defmodule Innerpeace.Db.Repo.Migrations.AlterTableProductsAddingProductCode do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :code, :string
    end
  end
end
