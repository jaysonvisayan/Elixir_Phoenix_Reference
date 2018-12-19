defmodule Innerpeace.Db.Repo.Migrations.CreateAccountGroupPersonnels do
  use Ecto.Migration

  def change do
    create table(:account_group_personnels, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_group_id, references(:account_groups, type: :binary_id, on_delete: :nothing)
      add :personnel, :string
      add :specialization, :string
      add :location, :string
      add :schedule, :string
      add :no_of_personnel, :integer
      add :payment_of_mode, :string
      add :retainer_fee, :string
      add :amount, :integer

      add :created_by_id, :binary_id
      add :updated_by_id, :binary_id

      timestamps()
    end
    create index(:account_group_personnels, [:account_group_id])
  end
end
