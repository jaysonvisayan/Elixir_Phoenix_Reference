defmodule Innerpeace.Db.Repo.Migrations.AddAdmissionDateAndDischargeDateToAuthorization do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :admission_datetime, :utc_datetime
      add :discharge_datetime, :utc_datetime
      add :availment_type, :string
      #add :number, :string
    end
  end
end
