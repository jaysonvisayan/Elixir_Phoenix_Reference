defmodule Innerpeace.Db.Repo.Migrations.AddRelationshipInContactUsedForMemberlink do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      add :relationship, :string
      add :middle_name, :string
    end
  end
end
