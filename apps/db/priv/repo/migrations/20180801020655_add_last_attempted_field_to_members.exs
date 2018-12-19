defmodule Innerpeace.Db.Repo.Migrations.AddLastAttemptedFieldToMembers do
  use Ecto.Migration

  def up do
    alter table(:members) do
      add :last_attempted, :utc_datetime
    end
  end

  def down do
    alter table(:members) do
      remove :last_attempted
    end
  end

end
