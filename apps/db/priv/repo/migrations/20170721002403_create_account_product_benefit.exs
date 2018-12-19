defmodule Innerpeace.Db.Repo.Migrations.CreateAccountProductBenefit do
  use Ecto.Migration

  def change do
    create table(:account_product_benefits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :limit_type, :string
      add :limit_value, :string

      add :account_product_id, references(:account_products, type: :binary_id, on_delete: :delete_all)
      add :product_benefit_id, references(:product_benefits, type: :binary_id, on_delete: :nothing)
      timestamps()
    end
    create index(:account_product_benefits, [:account_product_id])
    create index(:account_product_benefits, [:product_benefit_id])
  end
end
