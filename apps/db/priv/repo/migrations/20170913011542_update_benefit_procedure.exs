defmodule Innerpeace.Db.Repo.Migrations.UpdateBenefitProcedure do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE benefit_procedures DROP CONSTRAINT benefit_procedures_procedure_id_fkey"
    alter table(:benefit_procedures) do
      modify :procedure_id, references(:payor_procedures, type: :binary_id, on_delete: :nothing)
    end
  end

end
