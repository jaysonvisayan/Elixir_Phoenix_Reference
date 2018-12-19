defmodule Innerpeace.Db.Repo.Migrations.CreateAcuScheduleProduct do
  use Ecto.Migration

  def change do
    create table(:acu_schedule_products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_id, references(:products, type: :binary_id, on_delete: :delete_all)
      add :acu_schedule_id, references(:acu_schedules, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
    create index(:acu_schedule_products, [:product_id])
    create index(:acu_schedule_products, [:acu_schedule_id])
  end
end
