defmodule Innerpeace.Db.Repo.Migrations.DropExclusionNameIndex do
  use Ecto.Migration

  def change do
   	drop unique_index(:exclusions, [:name])
  end
end
