defmodule Innerpeace.Db.Repo.Migrations.AddApproverAndDateInAuthorization do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :approved_by_id, references(:users, type: :binary_id)
      add :approved_datetime, :utc_datetime
    end
  end
end
