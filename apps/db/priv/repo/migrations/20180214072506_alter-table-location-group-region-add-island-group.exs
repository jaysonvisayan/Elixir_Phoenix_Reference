defmodule :"Elixir.Innerpeace.Db.Repo.Migrations.Alter-table-location-group-region-add-island-group" do
  use Ecto.Migration

  def change do
    alter table(:location_group_regions) do
      add :island_group, :string
    end
  end
end
