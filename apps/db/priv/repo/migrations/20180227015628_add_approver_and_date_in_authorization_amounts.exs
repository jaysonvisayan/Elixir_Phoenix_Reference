defmodule Innerpeace.Db.Repo.Migrations.AddApproverAndDateInAuthorizationAmounts do
  use Ecto.Migration

  def change do
  	alter table(:authorization_amounts) do
      add :approved_by_id, references(:users, type: :binary_id)
      add :approved_datetime, :utc_datetime
    end
  end
end
