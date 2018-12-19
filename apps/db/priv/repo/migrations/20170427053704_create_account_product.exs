defmodule Innerpeace.Db.Repo.Migrations.CreateAccountProduct do
  use Ecto.Migration

  def change do
    create table(:account_products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :type, :string
      add :limit_applicability, :string
      add :limit_type, :string
      add :limit_amount, :decimal
      add :status, :string
      add :standard_product, :string
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all)
      add :product_id, references(:products, type: :binary_id, on_delete: :nothing)

      timestamps()
    end
    create index(:account_products, [:account_id])
    create index(:account_products, [:product_id])
  end
end
