defmodule Innerpeace.Db.Repo.Migrations.CreateClusterLog do
  use Ecto.Migration

  def change do
  	create table(:cluster_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :cluster_id, references(:clusters, type: :binary_id, on_delete: :nothing)
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :message, :text

      timestamps()
  	end

  	create index(:cluster_logs, [:cluster_id])
    create index(:cluster_logs, [:user_id])

  end
end
