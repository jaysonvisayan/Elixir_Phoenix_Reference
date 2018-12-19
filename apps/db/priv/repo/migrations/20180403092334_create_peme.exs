defmodule Innerpeace.Db.Repo.Migrations.CreatePeme do
  use Ecto.Migration

  def change do
    create table(:pemes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :peme_id, :string
      add :type, :string
      add :package_id, references(:packages, type: :binary_id, on_delete: :nothing)
      add :request_date, :date
      add :date_from, :date
      add :date_to, :date
      add :facility_id, references(:facilities, type: :binary_id, on_delete: :nothing)
      add :status, :string

      timestamps()
    end
    create unique_index(:pemes, :peme_id)
    create index(:pemes, [:package_id, :facility_id])
  end
end
