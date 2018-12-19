defmodule Innerpeace.Db.Repo.Migrations.AlterProcedureDescriptionToText do
  use Ecto.Migration

  def change do
    alter table(:procedures) do
      modify :description, :text
    end

    alter table(:payor_procedures) do
      modify :description, :text
    end
  end
end
