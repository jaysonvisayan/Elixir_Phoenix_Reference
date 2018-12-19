defmodule Innerpeace.Db.Repo.Migrations.AddApprovedDatetimeToPeme do
  use Ecto.Migration

  def up do
    alter table(:pemes) do
      add :approved_datetime, :utc_datetime
    end
  end

  def down do
    alter table(:pemes) do
      remove :approved_datetime
    end
  end
end
