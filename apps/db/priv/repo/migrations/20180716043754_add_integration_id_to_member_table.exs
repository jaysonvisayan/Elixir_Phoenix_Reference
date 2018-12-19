defmodule Innerpeace.Db.Repo.Migrations.AddIntegrationIdToMemberTable do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :integration_id, :string
    end
  end
end
