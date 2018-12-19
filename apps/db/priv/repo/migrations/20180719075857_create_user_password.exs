defmodule Innerpeace.Db.Repo.Migrations.CreateUserPassword do
  use Ecto.Migration

  def up do
    create table(:user_passwords, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :hashed_password, :string

      timestamps()
    end
  end

  def down do
    drop table(:user_passwords)
  end
end
