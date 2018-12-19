defmodule Innerpeace.Db.Repo.Migrations.AddIdToAuthorization do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :id, :binary_id, primary_key: true
    end
  end
end
