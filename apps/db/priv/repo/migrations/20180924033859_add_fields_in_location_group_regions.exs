defmodule Innerpeace.Db.Repo.Migrations.AddFieldsInLocationGroupRegions do
  use Ecto.Migration

  def change do
   alter table(:location_group_regions) do
      add :region_id, references(:regions, type: :binary_id, on_delete: :delete_all)
   end
  end
end
