defmodule Innerpeace.Db.Repo.Migrations.CreateProfileCorrection do
  use Ecto.Migration

  def up do
    create table(:profile_corrections) do
      add :first_name, :string
      add :middle_name, :string
      add :last_name, :string
      add :suffix, :string
      add :birth_date, :date
      add :gender, :string
      add :id_card, :string
      add :status, :string

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create index(:profile_corrections, [:user_id])
  end

  def down do
    drop table(:profile_corrections)
  end
end