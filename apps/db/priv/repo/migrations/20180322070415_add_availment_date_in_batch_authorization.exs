defmodule Innerpeace.Db.Repo.Migrations.AddAvailmentDateInBatchAuthorization do
  use Ecto.Migration

  def change do
  	alter table(:batch_authorizations) do
      add :availment_date, :date
    end
  end
end
