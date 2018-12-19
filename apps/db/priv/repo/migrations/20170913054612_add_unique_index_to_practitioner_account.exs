defmodule Innerpeace.Db.Repo.Migrations.AddUniqueIndexToPractitionerAccount do
  use Ecto.Migration

  def change do
    create unique_index(:practitioner_accounts, [:practitioner_id, :account_group_id])
  end
end
