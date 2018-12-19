defmodule Innerpeace.Db.Repo.Migrations.AddUsernamePasswordInApiAddresses do
  use Ecto.Migration

  def change do
    alter table(:api_addresses) do
      add :username, :string
      add :password, :string
    end
  end
end
