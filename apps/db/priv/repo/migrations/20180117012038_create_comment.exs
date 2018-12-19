defmodule Innerpeace.Db.Repo.Migrations.CreateComment do
  use Ecto.Migration

  def change do
    create table(:comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :comment, :text
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)
      add :batch_id, references(:batches, type: :binary_id)

      timestamps()
    end
  end
end
