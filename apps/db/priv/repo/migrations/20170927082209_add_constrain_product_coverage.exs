defmodule Innerpeace.Db.Repo.Migrations.AddConstrainProductCoverage do
  use Ecto.Migration

  def change do
    create unique_index(:product_coverages, [:product_id, :coverage_id])
  end
end
