defmodule Innerpeace.Db.Repo.Migrations.CreateCluster do
  use Ecto.Migration

  def change do
  	create table(:clusters, primary_key: false) do
  		add :id, :binary_id, primary_key: true
  		add :code, :string
  		add :name, :string
  		add :step, :integer

  		add :industry_id, references(:industries, type: :binary_id, on_delete: :nothing)

  		timestamps()
  	end
  		create index(:clusters, [:industry_id])
  end
end
