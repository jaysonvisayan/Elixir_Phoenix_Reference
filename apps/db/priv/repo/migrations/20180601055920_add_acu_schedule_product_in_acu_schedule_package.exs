defmodule Innerpeace.Db.Repo.Migrations.AddAcuScheduleProductInAcuSchedulePackage do
  use Ecto.Migration

  def change do
    alter table(:acu_schedule_packages) do
      add :acu_schedule_product_id, references(:acu_schedule_products, type: :binary_id, on_delete: :delete_all)
    end
  end
end
