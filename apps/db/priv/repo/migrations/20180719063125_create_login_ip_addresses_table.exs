defmodule Innerpeace.Db.Repo.Migrations.CreateLoginIpAddressesTable do
  use Ecto.Migration

  def change do
    create table(:login_ip_addresses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ip_address, :string
      add :attempts, :integer

      timestamps()
    end
      create unique_index(:login_ip_addresses, [:ip_address])
  end

end
