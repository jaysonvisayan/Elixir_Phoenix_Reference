defmodule Innerpeace.Db.Repo.Migrations.CreateAuthorizationRuv do
  use Ecto.Migration

  def change do
    create table(:authorization_ruvs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :authorization_id, references(:authorizations, type: :binary_id)
      add :facility_ruv_id, references(:facility_ruvs, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)
      add :member_product_id, references(:member_products, type: :binary_id)
      add :philhealth_covered, :decimal

      timestamps()
    end
  end
end
