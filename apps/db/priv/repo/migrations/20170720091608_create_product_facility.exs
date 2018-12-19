defmodule Innerpeace.Db.Repo.Migrations.CreateProductFacility do
  use Ecto.Migration

  def change do
    create table(:product_facilities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :facility_id, references(:facilities, type: :binary_id, on_delete: :nothing)
      add :product_id, references(:products, type: :binary_id, on_delete: :nothing)
      add :is_included, :boolean
      add :coverage_id, :string
      timestamps()
    end
    create index(:product_facilities, [:facility_id])
    create index(:product_facilities, [:product_id])
  end
end
