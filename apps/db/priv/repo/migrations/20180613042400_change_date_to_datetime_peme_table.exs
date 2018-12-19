defmodule Innerpeace.Db.Repo.Migrations.ChangeDateToDatetimePemeTable do
  use Ecto.Migration

  def change do
    alter table(:pemes) do
      remove :request_date
      remove :registration_date
      add :request_date, :utc_datetime
      add :registration_date, :utc_datetime
    end
  end
end
