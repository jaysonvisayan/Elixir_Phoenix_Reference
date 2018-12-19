defmodule Innerpeace.Db.Repo.Migrations.CreateUserAccessActivationLog do
  use Ecto.Migration

  def change do
    create table(:user_access_activation_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :code, :string
      add :employee_name, :string
      add :status, :string
      add :remarks, :text

      add :user_access_activation_file_id, references(:user_access_activation_files, type: :binary_id, on_delete: :delete_all)
      add :created_by_id, references(:users, type: :binary_id)

      timestamps()
    end
    create index(:user_access_activation_logs, [:user_access_activation_file_id])
  end
end
