defmodule Innerpeace.Db.Repo.Migrations.AlterTableAddUserInCluster do
  use Ecto.Migration

  def change do
  	alter table(:clusters) do
      add :created_by, :binary_id
      add :updated_by, :binary_id
    end
  end
end
