defmodule Innerpeace.Db.Repo.Migrations.CreateClaimSession do
  use Ecto.Migration

  def change do
    create table(:claim_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :claims_id, references(:claims, type: :binary_id)
      add :member_id, references(:members, type: :binary_id)
      add :facility_id, references(:facilities, type: :binary_id)
      add :coverage, references(:coverages, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)
      add :benefit_packge_id, references(:benefit_packages, type: :binary_id)

      timestamps()
    end
  end
end
