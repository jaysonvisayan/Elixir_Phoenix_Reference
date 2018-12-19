defmodule Innerpeace.Db.Repo.Migrations.PayorProceduresUniqueCode do
  use Ecto.Migration

  def change do
    create unique_index(:payor_procedures, [:code])
  end
end
