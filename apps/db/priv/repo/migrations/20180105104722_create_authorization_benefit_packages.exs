defmodule Innerpeace.Db.Repo.Migrations.CreateAuthorizationBenefitPackages do
  use Ecto.Migration

  def change do
    create table(:authorization_benefit_packages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :authorization_id, references(:authorizations, type: :binary_id)
      add :benefit_package_id, references(:benefit_packages, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
    end

    alter table(:authorizations) do
      add :room_id, references(:rooms, type: :binary_id)
    end
  end
end
