defmodule Innerpeace.Db.Repo.Migrations.CreateApiAddress do
  use Ecto.Migration

  def up do
    create table(:api_addresses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :address, :string

      timestamps()
    end
  end

  def down do
    drop table(:api_addresses)
  end
end
