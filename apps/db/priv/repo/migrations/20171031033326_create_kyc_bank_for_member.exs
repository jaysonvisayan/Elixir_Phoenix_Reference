defmodule Innerpeace.Db.Repo.Migrations.CreateKycBankForMember do
  use Ecto.Migration

  def change do
    create table(:kyc_banks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :member_id, references(:members, type: :binary_id, on_delete: :delete_all)
      add :country, :string
      add :city, :string
      add :citizenship, :string
      add :civil_status, :string
      add :mother_maiden, :string
      add :tin, :string
      add :sss_number, :string
      add :unified_id_number, :string
      add :educational_attainment, :string
      add :position_title, :string
      add :occupation, :string
      add :source_of_fund, :string
      add :company_name, :string
      add :company_branch, :string
      add :nature_of_work, :string
      timestamps()
    end
    create index(:kyc_banks, [:member_id])
  end
end
