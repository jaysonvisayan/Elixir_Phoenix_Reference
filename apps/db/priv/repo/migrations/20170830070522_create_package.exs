defmodule Innerpeace.Db.Repo.Migrations.CreatePackage do
  use Ecto.Migration

  def change do
  	create table(:packages, primary_key: false) do
  		add :id, :binary_id, primary_key: true
  		add :code, :string
  		add :name, :string
  		add :step, :integer

  		timestamps()
  	end
  end
end
