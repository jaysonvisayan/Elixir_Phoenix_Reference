defmodule Innerpeace.Db.Repo.Migrations.AddConstraintOnCluster do
  use Ecto.Migration

  def change do
  	alter table(:clusters) do
         modify :code, :string
    end
    create unique_index(:clusters, [:code])
  end
end
