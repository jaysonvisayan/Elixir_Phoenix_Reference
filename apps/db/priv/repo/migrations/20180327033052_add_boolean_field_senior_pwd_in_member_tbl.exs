defmodule Innerpeace.Db.Repo.Migrations.AddBooleanFieldSeniorPwdInMemberTbl do
  use Ecto.Migration

  def up do
    alter table(:members) do
      add :senior, :boolean
      add :pwd, :boolean
    end
  end

  def down do
    alter table(:members) do
      remove :senior
      remove :pwd
    end
  end

end
