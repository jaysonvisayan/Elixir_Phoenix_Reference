defmodule Innerpeace.Db.Repo.Migrations.CreateAccountGroup do
  use Ecto.Migration

  def change do
    create table(:account_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :code, :string
      add :type, :string
      add :description, :string
      add :segment, :string
      add :phone_no, :string
      add :email, :string
      add :remarks, :string
      add :photo, :string

      add :industry_id, references(:industries, type: :binary_id, on_delete: :nothing)

      timestamps()
    end
    create unique_index(:account_groups, [:code])
    create unique_index(:account_groups, [:name])
    create index(:account_groups, [:industry_id])
  end
end
