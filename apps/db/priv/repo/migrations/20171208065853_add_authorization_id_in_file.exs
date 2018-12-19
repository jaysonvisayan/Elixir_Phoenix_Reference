defmodule Innerpeace.Db.Repo.Migrations.AddAuthorizationIdInFile do
  use Ecto.Migration

  def change do
    alter table(:files) do
      add :authorization_id, references(:authorizations, type: :binary_id, on_delete: :delete_all)
    end
  end
end
