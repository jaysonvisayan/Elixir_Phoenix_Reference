defmodule Innerpeace.Db.Repo.Migrations.CreateRuvs do
  use Ecto.Migration

  def change do
    create table(:ruvs, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :code, :string
      add :description, :string
      add :type, :string
      add :value, :decimal
      add :effectivity_date, :date

      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end
end
