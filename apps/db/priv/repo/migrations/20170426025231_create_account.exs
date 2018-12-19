defmodule Innerpeace.Db.Repo.Migrations.CreateAccount do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :start_date, :date
      add :end_date, :date
      add :major_version, :integer
      add :minor_version, :integer
      add :build_version, :integer
      add :created_by, :binary_id
      add :updated_by, :binary_id
      add :status, :string
      add :step, :integer

      add :account_group_id, references(:account_groups, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
    create index(:accounts, [:account_group_id])
  end
end
