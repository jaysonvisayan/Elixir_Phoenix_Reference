defmodule Innerpeace.Db.Repo.Migrations.CreateBank do
  use Ecto.Migration

  def change do
    create table(:banks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_name, :string
      add :account_no, :string
      add :status, :string
      add :account_group_id, references(:account_groups, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
    create index(:banks, [:account_group_id])
  end
end
