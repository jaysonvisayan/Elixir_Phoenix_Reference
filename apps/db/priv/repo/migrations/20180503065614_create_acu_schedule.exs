defmodule Innerpeace.Db.Repo.Migrations.CreateAcuSchedule do
  use Ecto.Migration

  def change do
    create table(:acu_schedules, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :batch_no, :integer
      add :no_of_members, :integer
      add :no_of_guaranteed, :integer
      add :member_type, :string
      add :date_from, :date
      add :date_to, :date

      add :created_by_id, :binary_id
      add :updated_by_id, :binary_id
      add :account_group_id, references(:account_groups, type: :binary_id, on_delete: :nothing)
      add :facility_id, references(:facilities, type: :binary_id, on_delete: :nothing)

      timestamps()
    end
  end
end
