defmodule Innerpeace.Db.Repo.Migrations.CreateBankBranch do
  use Ecto.Migration

  def change do
    create table(:bank_branches, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :unit_no, :string
      add :bldg_name, :string
      add :street_name, :string
      add :municipality, :string
      add :province, :string
      add :region, :string
      add :country, :string
      add :postal_code, :string
      add :phone, :string
      add :branch_type, :string
      add :bank_id, references(:banks, type: :binary_id)

      timestamps()
    end

    create index(:bank_branches, [:bank_id])
  end
end
