defmodule Innerpeace.Db.Repo.Migrations.AddRequestedDateInAuthorization do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :requested_datetime, :utc_datetime
    end
  end
end
