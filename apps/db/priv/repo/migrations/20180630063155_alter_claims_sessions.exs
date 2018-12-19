defmodule Innerpeace.Db.Repo.Migrations.AlterClaimsSessions do
  use Ecto.Migration

  def up do
    drop table(:claim_sessions)
    create table(:claim_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :claim_id, references(:claims, type: :binary_id)
      add :member_id, references(:members, type: :binary_id)
      add :facility_id, references(:facilities, type: :binary_id)
      add :coverage_id, references(:coverages, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)
      add :benefit_package_id, references(:benefit_packages, type: :binary_id)

      timestamps()
    end
  end

  def down do
    drop table(:claim_sessions)
    create table(:claim_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :claim_id, references(:claims, type: :binary_id)
      add :member_id, references(:members, type: :binary_id)
      add :facility_id, references(:facilities, type: :binary_id)
      add :coverage, references(:coverages, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)
      add :benefit_package_id, references(:benefit_packages, type: :binary_id)

      timestamps()
    end
  end

end
