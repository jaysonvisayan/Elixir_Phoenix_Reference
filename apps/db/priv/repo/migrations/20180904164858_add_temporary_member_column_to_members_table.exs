defmodule Innerpeace.Db.Repo.Migrations.AddTemporaryMemberColumnToMembersTable do
  use Ecto.Migration

  def up do
    alter table(:members) do
      add :temporary_member, :boolean, default: false
    end
  end

  def down do
    alter table(:members) do
      remove :temporary_member
    end
  end
end
