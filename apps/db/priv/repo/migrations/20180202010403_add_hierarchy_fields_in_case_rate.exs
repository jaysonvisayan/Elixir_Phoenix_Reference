defmodule Innerpeace.Db.Repo.Migrations.AddHierarchyFieldsInCaseRate do
  use Ecto.Migration

  def change do
  	alter table(:case_rates) do
      add :hierarchy1, :integer
      add :hierarchy2, :integer
      add :discount_percentage1, :integer
      add :discount_percentage2, :integer
    end
  end
end
