defmodule Innerpeace.Db.Repo.Migrations.CreateBatchAuthorizationFile do
  use Ecto.Migration

  def change do
  	create table(:batch_authorization_files, primary_key: false) do
  	  add :id, :binary_id, primary_key: true
      add :batch_authorization_id, references(:batch_authorizations, type: :binary_id)
      add :file_id, references(:files, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
    end

  end
end
