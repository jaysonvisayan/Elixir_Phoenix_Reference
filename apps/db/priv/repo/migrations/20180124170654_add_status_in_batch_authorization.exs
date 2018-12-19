defmodule Innerpeace.Db.Repo.Migrations.AddStatusInBatchAuthorization do
  use Ecto.Migration

  def change do
  	alter table(:batch_authorizations) do
      add :status, :string
    end
  end
end
