defmodule Innerpeace.Db.Repo.Migrations.CreateProductCoverageLocationGroup do
  use Ecto.Migration

  def change do
    create table(:product_coverage_location_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_coverage_id, references(:product_coverages, type: :binary_id)
      add :location_group_id, references(:location_groups, type: :binary_id)

      timestamps()
    end
  end
end
