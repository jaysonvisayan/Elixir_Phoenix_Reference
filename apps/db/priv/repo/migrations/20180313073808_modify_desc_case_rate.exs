defmodule Innerpeace.Db.Repo.Migrations.ModifyDescCaseRate do
  use Ecto.Migration

  def up do
    alter table(:case_rates) do
      modify :description , :text
    end
  end

  def down do
    alter table(:case_rates) do
      modify :description , :string
    end
  end
end
