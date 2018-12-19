defmodule Innerpeace.Db.Repo.Migrations.AlterEmailForKyc do
  use Ecto.Migration

  def change do
    alter table(:emails) do
      add :kyc_bank_id, references(:kyc_banks, type: :binary_id, on_delete: :delete_all)
    end
  end
end
