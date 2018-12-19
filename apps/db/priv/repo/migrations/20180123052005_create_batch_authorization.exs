defmodule Innerpeace.Db.Repo.Migrations.CreateBatchAuthorization do
  use Ecto.Migration

  def change do
  	create table(:batch_authorizations, primary_key: false) do
  	  add :id, :binary_id, primary_key: true
      add :authorization_id, references(:authorizations, type: :binary_id)
      add :batch_id, references(:batches, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      add :assessed_amount, :decimal
      add :reason, :string

      timestamps()
    end
  end
end
