defmodule Innerpeace.Db.Repo.Migrations.CreateProductExclusion do
  use Ecto.Migration

  def change do
    create table(:product_exclusions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :exclusion_id, references(:exclusions, type: :binary_id, on_delete: :nothing)
      add :product_id, references(:products, type: :binary_id, on_delete: :nothing)

      add :start_date, :date
      add :end_date, :date

      timestamps()
    end
    create index(:product_exclusions, [:exclusion_id])
    create index(:product_exclusions, [:product_id])
  end
end
