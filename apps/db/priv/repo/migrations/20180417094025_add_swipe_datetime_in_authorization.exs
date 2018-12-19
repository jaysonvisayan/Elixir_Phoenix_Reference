defmodule Innerpeace.Db.Repo.Migrations.AddSwipeDatetimeInAuthorization do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :swipe_datetime, :utc_datetime
    end
  end
end
