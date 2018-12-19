defmodule Innerpeace.Db.Repo.Migrations.CreateUserAccessActivationFile do
  use Ecto.Migration

  def change do
    create table(:user_access_activation_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :batch_no, :string

      add :created_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end
end
