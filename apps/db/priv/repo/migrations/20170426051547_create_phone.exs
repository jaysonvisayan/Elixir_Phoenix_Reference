defmodule Innerpeace.Db.Repo.Migrations.CreatePhone do
  use Ecto.Migration

  def change do
    create table(:phones, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :number, :string
      add :type, :string
      add :contact_id, references(:contacts, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
  end
end
