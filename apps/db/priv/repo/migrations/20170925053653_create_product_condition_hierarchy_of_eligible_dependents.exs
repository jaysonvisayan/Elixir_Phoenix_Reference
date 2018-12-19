defmodule Innerpeace.Db.Repo.Migrations.CreateProductConditionHierarchyOfEligibleDependents do
  use Ecto.Migration

  def change do
    create table(:product_condition_hierarchy_of_eligible_dependents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_id, references(:products, type: :binary_id, on_delete: :delete_all)
      add :hierarchy_type, :string
      add :dependent, :string
      add :ranking, :integer

      timestamps()
    end

    create index(:product_condition_hierarchy_of_eligible_dependents, [:product_id])
  end
end
