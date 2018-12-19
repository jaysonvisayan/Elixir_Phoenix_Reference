defmodule Innerpeace.Db.Repo.Migrations.AddSharedLimitAmountAndHierarchyWaiverInProductTable do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :shared_limit_amount, :decimal
      add :hierarchy_waiver, :string
    end
  end
end
