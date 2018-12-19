defmodule Innerpeace.Db.Repo.Migrations.CreateEmail do
  use Ecto.Migration

  def change do

    create table(:emails, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :address, :string
      add :contact_id, references(:contacts, type: :binary_id)

      timestamps()
    end
  end
end
