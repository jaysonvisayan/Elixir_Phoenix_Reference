defmodule Innerpeace.Db.Repo.Migrations.CreateDiagnosis do
  use Ecto.Migration

  def change do
    create table(:diagnoses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :code, :string
      add :name, :string
      add :classification, :string
      add :type, :string
      add :group_description, :string
      add :description, :string
      add :congenital, :string
      timestamps()
    end
  end
end
