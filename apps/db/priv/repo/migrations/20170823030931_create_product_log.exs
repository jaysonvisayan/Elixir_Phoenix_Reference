defmodule Innerpeace.Db.Repo.Migrations.CreateProductLogs do
  use Ecto.Migration

  def change do
    create table(:product_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_id, references(:products, type: :binary_id, on_delete: :nothing)
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)
      add :message, :text

      timestamps()
    end
    create index(:product_logs, [:product_id])
    create index(:product_logs, [:user_id])
  end
end
