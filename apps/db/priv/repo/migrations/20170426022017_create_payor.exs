defmodule Innerpeace.Db.Repo.Migrations.CreatePayor do
  use Ecto.Migration

  def change do
    create table(:payors, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :legal_name, :string
      add :tax_number, :integer
      add :type, :string
      add :status, :string
      add :code, :string

      timestamps()
    end
  end
end
