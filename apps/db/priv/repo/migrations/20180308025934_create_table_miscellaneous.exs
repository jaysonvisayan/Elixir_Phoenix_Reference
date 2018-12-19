defmodule Innerpeace.Db.Repo.Migrations.CreateTableMiscellaneous do
  use Ecto.Migration

  def change do
    create table(:miscellaneous, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :code, :string
      add :description, :string
      add :price, :decimal
      add :step, :string
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end
end
