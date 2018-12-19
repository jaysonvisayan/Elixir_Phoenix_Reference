defmodule Innerpeace.Db.Repo.Migrations.AddAvailmentDateOnAuthorization do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :availment_date, :date
    end
  end
end
