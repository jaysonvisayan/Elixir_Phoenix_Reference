defmodule Innerpeace.Db.Repo.Migrations.CreateBatch do
  use Ecto.Migration

  def change do
    create table(:batches, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :batch_no, :string
      add :name, :string
      add :date_received, :date
      add :date_due, :date
      add :soa_ref_no, :string
      add :soa_amount, :string
      add :estimate_no_of_claims, :string
      add :mode_of_receiving, :string
      add :status, :string
      add :aso, :string
      add :fullrisk, :string
      add :funding_arrangement, :string
      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)
      add :practitioner_id, references(:practitioners, type: :binary_id)
      add :facility_id, references(:facilities, type: :binary_id)

      timestamps()
    end
    create unique_index(:batches, [:batch_no])
  end
end
