defmodule Innerpeace.Db.Repo.Migrations.UpdatePayorProcedureConstraint do
  use Ecto.Migration

  def change do
    drop unique_index(:payor_procedures, [:code])
  end
end
