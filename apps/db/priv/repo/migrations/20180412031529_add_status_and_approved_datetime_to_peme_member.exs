defmodule Innerpeace.Db.Repo.Migrations.AddStatusAndApprovedDatetimeToPemeMember do
  use Ecto.Migration

  def up do
    alter table(:peme_members) do
      add :status, :string
      add :approved_datetime, :utc_datetime
    end
    alter table(:pemes) do
      remove :approved_datetime
    end
  end

  def down do
    alter table(:peme_members) do
      remove :status
      remove :approved_datetime
    end
    alter table(:pemes) do
      add :approved_datetime, :utc_datetime
    end
  end
end
