defmodule Innerpeace.Db.Repo.Migrations.AddFieldsInLocationGroups do
  use Ecto.Migration

  def change do
   alter table(:location_groups) do
    add :selecting_type, :string
    add :version, :string
    add :status, :string
   end
  end
end
