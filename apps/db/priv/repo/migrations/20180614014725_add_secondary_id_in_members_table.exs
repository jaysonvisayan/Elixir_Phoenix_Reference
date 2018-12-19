defmodule Innerpeace.Db.Repo.Migrations.AddSecondaryIdInMembersTable do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :secondary_id, :string
    end
  end
end
