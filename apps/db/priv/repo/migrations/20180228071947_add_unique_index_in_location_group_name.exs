defmodule Innerpeace.Db.Repo.Migrations.AddUniqueIndexInLocationGroupName do
  use Ecto.Migration

  def change do
    alter table(:location_groups) do
      modify :name, :string
    end
    create unique_index(:location_groups, [:name])
  end
end
