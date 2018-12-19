defmodule Innerpeace.Db.Repo.Migrations.AddColumnAvailmentDateToPemeTable do
  use Ecto.Migration

  def change do
    alter table(:pemes) do
      add :availment_date, :date
    end
  end
end
