defmodule Innerpeace.Db.Repo.Migrations.CreateAccountComment do
  use Ecto.Migration

  def change do
  	create table(:account_comments, primary_key: false) do
  		add :id, :binary_id, primary_key: true
  		add :comment, :string
  		add :account_id, references(:accounts, type: :binary_id, on_delete: :nothing)
  		add :user_id, references(:users, type: :binary_id, on_delete: :nothing)

  		timestamps()
  	end

  	create index(:account_comments, [:account_id])
  	create index(:account_comments, [:user_id])

  end
end
