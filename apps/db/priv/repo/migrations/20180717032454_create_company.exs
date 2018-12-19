defmodule Innerpeace.Db.Repo.Migrations.CreateCompany do
  use Ecto.Migration

  def change do
  	create table(:companies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :company_name, :string
      add :company_code, :string

      timestamps()
    end
  end
end
