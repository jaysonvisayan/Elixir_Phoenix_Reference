defmodule Innerpeace.Db.Repo.Migrations.CreateMemberProduct do
  use Ecto.Migration

  def change do
    create table(:member_products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :member_id, references(:members, type: :binary_id)
      add :product_code, references(:products, column: :code, type: :string)

      timestamps()
    end
    create unique_index(:member_products, [:member_id, :product_code])
  end
end
