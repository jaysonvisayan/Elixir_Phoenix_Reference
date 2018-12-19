defmodule Innerpeace.Db.Repo.Migrations.AddIndexFieldInRegion do
  use Ecto.Migration

  def change do
    alter table(:regions) do
      add :index, :integer
    end
  end
end
