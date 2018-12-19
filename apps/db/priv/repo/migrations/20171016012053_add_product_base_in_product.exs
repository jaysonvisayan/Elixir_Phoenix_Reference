defmodule Innerpeace.Db.Repo.Migrations.AddProductBaseInProduct do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :product_base, :string
    end
  end
end
