defmodule Innerpeace.Db.Repo.Migrations.CreateMemberEmergencyContact do
  use Ecto.Migration

  def change do
    create table(:emergency_contact, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :member_id, references(:members, type: :binary_id)
      add :ecp_name, :string
      add :ecp_relationship, :string
      add :ecp_phone, :string
      add :ecp_phone2, :string
      add :ecp_email, :string

      add :hospital_name, :string
      add :hospital_telephone, :string

      add :hmo_name, :string
      add :member_name, :string
      add :card_number, :string
      add :policy_number, :string
      add :customer_care_number, :string

      add :created_by_id, references(:users, type: :binary_id)
      add :updated_by_id, references(:users, type: :binary_id)

      timestamps()
    end
  end

end
