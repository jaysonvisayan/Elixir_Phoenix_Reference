defmodule Innerpeace.Db.Repo.Migrations.AddEditFieldsOnAuthorization do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :edited_by_id, references(:users, type: :binary_id)
    end
  end
end
