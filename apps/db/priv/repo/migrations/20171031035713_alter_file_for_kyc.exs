defmodule Innerpeace.Db.Repo.Migrations.AlterFileForKyc do
  use Ecto.Migration

  def change do
    alter table(:files) do
      add :link, :string
      add :link_type, :string
      add :kyc_bank_id, references(:kyc_banks, type: :binary_id, on_delete: :delete_all)
    end
  end
end
