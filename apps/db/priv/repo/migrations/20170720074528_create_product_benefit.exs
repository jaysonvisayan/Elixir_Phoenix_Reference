defmodule Innerpeace.Db.Repo.Migrations.CreateProductBenefit do
  use Ecto.Migration

  def change do
    create table(:product_benefits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :benefit_id, references(:benefits, type: :binary_id, on_delete: :nothing)
      add :product_id, references(:products, type: :binary_id, on_delete: :nothing)
      add :limit_type, :string
      add :limit_value, :integer

      timestamps()
    end
    create index(:product_benefits, [:benefit_id])
    create index(:product_benefits, [:product_id])
  end
end
