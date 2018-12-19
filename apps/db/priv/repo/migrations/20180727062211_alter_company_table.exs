defmodule Innerpeace.Db.Repo.Migrations.AlterCompanyTable do
  use Ecto.Migration

  def change do
  	create unique_index(:companies, [:code])
  end
end
