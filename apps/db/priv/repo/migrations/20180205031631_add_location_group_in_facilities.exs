defmodule Innerpeace.Db.Repo.Migrations.AddLocationGroupInFacilities do
  use Ecto.Migration

  def change do
  	alter table(:facilities) do
      add :location_group, :string
    end
  end
end
