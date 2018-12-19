defmodule Innerpeace.Db.Repo.Migrations.CreateUserTerms do
  use Ecto.Migration

  def change do
    create table(:user_terms, primary_key: false)  do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :terms_n_condition_id, references(:terms_n_conditions, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
  end
end
