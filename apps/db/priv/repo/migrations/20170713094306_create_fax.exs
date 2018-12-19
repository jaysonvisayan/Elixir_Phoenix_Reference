defmodule Innerpeace.Db.Repo.Migrations.CreateFax do
  use Ecto.Migration

  def change do
    create table(:fax, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :number, :string
      add :prefix, :string

      add :contact_id, references(:contacts, type: :binary_id, on_delete: :delete_all)
      timestamps()
    end
  end
end
