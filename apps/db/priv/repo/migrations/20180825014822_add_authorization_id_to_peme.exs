defmodule Innerpeace.Db.Repo.Migrations.AddAuthorizationIdToPeme do
  use Ecto.Migration

  def up do
    alter table(:pemes) do
      add :authorization_id, references(:authorizations, type: :binary_id, on_delete: :delete_all)
    end
  end

  def down do
    alter table(:pemes) do
      remove :authorization_id
    end
  end
end
