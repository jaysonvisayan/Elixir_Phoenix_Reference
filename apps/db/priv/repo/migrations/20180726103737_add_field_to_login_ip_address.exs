defmodule Innerpeace.Db.Repo.Migrations.AddFieldToLoginIpAddress do
  use Ecto.Migration

  def change do
    alter table(:login_ip_addresses) do
      add :verify_attempts, :integer, default: 0
    end
  end
end
