defmodule Innerpeace.Db.Repo.Migrations.AlterExclusionProcedures do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE exclusion_procedures DROP CONSTRAINT exclusion_procedures_procedure_id_fkey"
    alter table(:exclusion_procedures) do
      modify :procedure_id, references(:payor_procedures, type: :binary_id, on_delete: :nothing)
    end
  end
end
