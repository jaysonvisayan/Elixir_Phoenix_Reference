defmodule Innerpeace.Db.Repo.Migrations.CreateAddress do
  use Ecto.Migration

  def change do
    create table(:addresses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :street, :string
      add :district, :string
      add :postal_code, :string
      add :city, :string
      add :country, :string
      add :category , :string
      add :type, :string
      add :contact_id, references(:contacts, type: :binary_id)

      timestamps()
    end
  end
end
