defmodule Innerpeace.Db.Repo.Migrations.AddFieldOnCaseRate do
  use Ecto.Migration

  def change do
  	alter table(:case_rates) do
      add :amount_up_to, :decimal
    end
  end
end
