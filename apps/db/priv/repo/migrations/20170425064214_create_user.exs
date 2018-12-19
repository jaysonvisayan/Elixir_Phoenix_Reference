defmodule Innerpeace.Db.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :string
      add :hashed_password, :string
      add :status, :string
      add :email, :string
      add :mobile, :string
      add :first_name, :string
      add :last_name, :string
      add :middle_name, :string
      add :birthday, :date
      add :title, :string
      add :suffix, :string
      add :gender, :string
      add :notify_through, :string
      add :profile_image, :string
      add :reset_token, :string
      add :password_token, :string
      add :created_by_id, :binary_id
      add :updated_by_id, :binary_id
      add :step, :integer
      add :is_admin, :boolean, default: false
      #newly added
      add :verification_code, :string

      timestamps()
    end
    create unique_index(:users, [:username])
    create unique_index(:users, [:email])
    create unique_index(:users, [:mobile])
  end
end
