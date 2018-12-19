defmodule Innerpeace.Db.Repo.Migrations.CreateAccountGroupCluster do
  use Ecto.Migration

  def change do
  	create table(:account_clusters, primary_key: false) do
  		add :id, :binary_id, primary_key: true
  		add :account_group_id, references(:account_groups, type: :binary_id, on_delete: :nothing)
  		add :cluster_id, references(:clusters, type: :binary_id, on_delete: :delete_all)

  		timestamps()
  	end

  		create index(:account_clusters, [:account_group_id])
  		create index(:account_clusters, [:cluster_id])
  end
end
