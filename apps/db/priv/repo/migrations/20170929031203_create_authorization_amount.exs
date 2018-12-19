defmodule Innerpeace.Db.Repo.Migrations.CreateAuthorizationAmount do
  use Ecto.Migration

  def change do
    create table(:authorization_amounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :coordinator_fee, :decimal
      add :consultation_fee, :decimal
      add :copayment, :decimal
      add :coinsurance_percentage, :integer
      add :covered_after_percentage, :integer
      add :pre_existing_percentage, :integer
      add :payor_covered, :decimal
      add :member_covered, :decimal

      add :authorization_id, references(:authorizations, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end
end
