defmodule Innerpeace.Db.Repo.Migrations.AddAuthorizationOtp do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :otp, :string
      add :otp_expiry, :utc_datetime
    end
  end
end
