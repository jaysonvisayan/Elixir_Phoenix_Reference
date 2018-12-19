defmodule Innerpeace.Db.Repo.Migrations.AddBankIdToPractitioner do
  use Ecto.Migration

  def change do
    alter table(:banks) do
      remove (:practitioner_id)
    end

    alter table(:practitioners) do
      add :bank_id, references(:banks, type: :binary_id, on_delete: :delete_all)
      add :account_no, :string
    end
    create index(:practitioners, [:bank_id])
  end
end
