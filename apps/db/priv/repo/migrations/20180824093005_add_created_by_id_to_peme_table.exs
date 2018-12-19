defmodule Innerpeace.Db.Repo.Migrations.AddCreatedByIdToPemeTable do
  use Ecto.Migration

  def change do
    alter table(:pemes) do
      add :created_by_id, references(:users, type: :binary_id)
    end
  end
end
