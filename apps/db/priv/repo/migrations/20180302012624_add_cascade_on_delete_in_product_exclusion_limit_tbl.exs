defmodule Innerpeace.Db.Repo.Migrations.AddCascadeOnDeleteInProductExclusionLimitTbl do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE product_exclusion_limits DROP CONSTRAINT product_exclusion_limits_product_exclusion_id_fkey"
    alter table(:product_exclusion_limits) do
      modify :product_exclusion_id, references(:product_exclusions, type: :binary_id, on_delete: :delete_all)
    end

  end

  def down do
    execute "ALTER TABLE product_exclusion_limits DROP CONSTRAINT product_exclusion_limits_product_exclusion_id_fkey"
    alter table(:product_exclusion_limits) do
      modify :product_exclusion_id, references(:product_exclusions, type: :binary_id, on_delete: :nothing)
    end

  end
end
