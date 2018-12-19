defmodule Innerpeace.Db.Repo.Migrations.DropAccountGroupUniqueAccountName do
  use Ecto.Migration

  def change do
    drop unique_index(:account_groups, [:name])
  end
end
