defmodule Innerpeace.Db.Repo.Migrations.AddIdsToPractitioner do
  use Ecto.Migration

  def change do
    alter table(:practitioners) do
      add :created_by_id, :binary_id
      add :updated_by_id, :binary_id
    end
  end
end
