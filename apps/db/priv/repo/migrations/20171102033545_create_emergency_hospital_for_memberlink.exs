defmodule Innerpeace.Db.Repo.Migrations.CreateEmergencyHospitalForMemberlink do
  use Ecto.Migration

  def change do
    create table(:emergency_hospitals, primary_key: false)  do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :phone, :string
      add :hmo, :string
      add :card_number, :integer
      add :policy_number, :integer
      add :customer_care_number, :integer
      add :member_id, references(:members, type: :binary_id)

      timestamps()
    end
  end
end
