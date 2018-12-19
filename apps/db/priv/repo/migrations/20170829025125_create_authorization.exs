defmodule Innerpeace.Db.Repo.Migrations.CreateAuthorization do
  use Ecto.Migration

  def change do
    create table(:authorizations, primary_key: false) do
      add :consultation_type, :string
      add :chief_complaint, :string
      add :internal_remarks, :string
      add :assessed_amount, :decimal
      add :total_amount, :decimal
      add :status, :string
      add :version, :integer

      add :member_id, references(:members, type: :binary_id)
      add :facility_id, references(:facilities, type: :binary_id)
      add :coverage_id, references(:coverages, type: :binary_id)
      add :special_approval_id, references(:dropdowns, type: :binary_id)
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end
end
