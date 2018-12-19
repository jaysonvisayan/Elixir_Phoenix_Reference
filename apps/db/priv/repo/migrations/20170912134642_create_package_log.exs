defmodule Innerpeace.Db.Repo.Migrations.CreatePackageLog do
  use Ecto.Migration

  def change do
  	create table(:package_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :package_id, references(:packages, type: :binary_id, on_delete: :nothing)
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :message, :text

      timestamps()
  	end

  	create index(:package_logs, [:package_id])
    create index(:package_logs, [:user_id])

  end
end
