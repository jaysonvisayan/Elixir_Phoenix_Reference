defmodule Innerpeace.Db.Repo.Migrations.AlterApiAddressesAddToken do
  use Ecto.Migration

  def change do
    alter table(:api_addresses) do
      add :token, :text
    end
  end
end
