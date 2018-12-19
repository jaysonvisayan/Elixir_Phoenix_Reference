defmodule Innerpeace.Db.Repo.Migrations.AddExclusionTypeInPayorProcedure do
  use Ecto.Migration

  def change do
    alter table(:payor_procedures) do
      add :exclusion_type, :string
    end
  end
end
