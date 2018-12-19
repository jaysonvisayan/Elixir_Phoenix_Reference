defmodule Innerpeace.Db.Repo.Migrations.RemoveApplicationInRole do
  use Ecto.Migration

  def change do
    alter table(:roles) do
      remove :application_id
    end
  end
end
