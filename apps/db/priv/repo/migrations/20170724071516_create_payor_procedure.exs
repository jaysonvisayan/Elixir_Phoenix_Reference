defmodule Innerpeace.Db.Repo.Migrations.CreatePayorProcedure do
  use Ecto.Migration

  def change do
    create table(:payor_procedures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :code, :string
      add :description, :string
      add :is_active, :boolean, default: true
      add :deactivation_date, :date

      add :procedure_id, references(:procedures, type: :binary_id, on_delete: :delete_all)
      add :payor_id, references(:payors, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
    create index(:payor_procedures, [:payor_id])
    create index(:payor_procedures, [:procedure_id])
  end

end
