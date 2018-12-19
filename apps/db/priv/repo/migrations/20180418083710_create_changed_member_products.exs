defmodule Innerpeace.Db.Repo.Migrations.CreateChangedMemberProducts do
  use Ecto.Migration

  def change do
    create table(:changed_member_products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :product_id, references(:products, type: :binary_id, on_delete: :delete_all)
      add :change_of_product_log_id, references(:change_of_product_logs, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
    create index(:changed_member_products, [:product_id])
    create index(:changed_member_products, [:change_of_product_log_id])
  end
end
