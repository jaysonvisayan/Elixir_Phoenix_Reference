defmodule Innerpeace.Db.Repo.Migrations.AddWebsiteToFacility do
  use Ecto.Migration

  def change do
    alter table(:facilities) do
      add :website, :string
    end
  end
end
