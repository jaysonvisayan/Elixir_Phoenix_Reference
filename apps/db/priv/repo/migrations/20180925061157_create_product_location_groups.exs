defmodule Innerpeace.Db.Repo.Migrations.CreateProductLocationGroups do
  use Ecto.Migration

  def up do
    create table(:product_location_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_id, references(:products, type: :binary_id)
      add :location_groups_id, references(:location_groups, type: :binary_id)

      timestamps()
    end
  end

  def down do
    drop table(:product_location_groups)
  end
end
