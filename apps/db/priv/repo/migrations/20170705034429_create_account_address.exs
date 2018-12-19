defmodule Innerpeace.Db.Repo.Migrations.CreateAccountGroupAddress do
  use Ecto.Migration

  def change do
    create table(:account_group_address, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :unit_no, :string
      add :street, :string
      add :district, :string
      add :postal_code, :string
      add :city, :string
      add :country, :string
      add :category , :string
      add :type, :string
      add :building_name, :string
      add :province, :string
      add :region, :string
      add :is_check, :boolean, default: true
      add :account_group_id, references(:account_groups, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end
    create index(:account_group_address, [:account_group_id])
  end
end
