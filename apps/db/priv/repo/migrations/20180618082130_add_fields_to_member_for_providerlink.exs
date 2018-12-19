defmodule Innerpeace.Db.Repo.Migrations.AddFieldsToMemberForProviderlink do
  use Ecto.Migration

  def up do
    alter table(:members) do
      add :attempts, :integer
      add :attempt_expiry, :utc_datetime
    end
  end

  def down do
    alter table(:members) do
      remove :attempts
      remove :attempt_expiry
    end
  end

end
