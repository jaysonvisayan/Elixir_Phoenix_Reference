defmodule Innerpeace.Db.Repo.Migrations.CreatePractitionerAccount do
  use Ecto.Migration

  def change do
    create table(:practitioner_accounts, primary_key: false)  do
      add :id, :binary_id, primary_key: true
      add :account_group_id, references(:account_groups, type: :binary_id, on_delete: :delete_all)
      add :practitioner_id, references(:practitioners, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
  end
end
