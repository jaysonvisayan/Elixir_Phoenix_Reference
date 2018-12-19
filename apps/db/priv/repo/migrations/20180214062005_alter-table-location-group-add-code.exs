defmodule :"Elixir.Innerpeace.Db.Repo.Migrations.Alter-table-location-group-add-code" do
  use Ecto.Migration

  def change do
    alter table(:location_groups) do
      add :code, :string
    end
  end
end
