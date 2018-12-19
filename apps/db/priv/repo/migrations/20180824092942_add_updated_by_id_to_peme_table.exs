defmodule Innerpeace.Db.Repo.Migrations.AddUpdatedByIdToPemeTable do
  use Ecto.Migration

  def change do
    alter table(:pemes) do
      add :updated_by_id, references(:users, type: :binary_id)
    end
  end
end
