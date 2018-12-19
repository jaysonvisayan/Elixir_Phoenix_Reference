defmodule Innerpeace.Db.Repo.Migrations.CreateChangeOfProductLogs do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:change_of_product_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :change_of_product_effective_date, :date
      add :reason, :string
      add :member_id, references(:members, type: :binary_id, on_delete: :delete_all)
      add :created_by_id, references(:users, type: :binary_id)

      timestamps()
    end
    create index(:change_of_product_logs, [:member_id])
    create index(:change_of_product_logs, [:created_by_id])
  end
end
