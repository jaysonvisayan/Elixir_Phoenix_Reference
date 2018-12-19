defmodule Innerpeace.Db.Repo.Migrations.AddDoctypeInBatchAuthorizationFile do
  use Ecto.Migration

  def change do
  	alter table(:batch_authorization_files) do
      add :document_type, :string
    end
  end
end
