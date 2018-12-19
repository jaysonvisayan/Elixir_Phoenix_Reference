defmodule Innerpeace.Db.Repo.Migrations.CreatePractitionerSpecialization do
  use Ecto.Migration

  def change do
    create table(:practitioner_specializations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :practitioner_id, references(:practitioners, type: :binary_id, on_delete: :delete_all)
      add :specialization_id, references(:specializations, type: :binary_id, on_delete: :nothing)

      timestamps()
    end
    create index(:practitioner_specializations, [:practitioner_id])
    create index(:practitioner_specializations, [:specialization_id])

  end
end
