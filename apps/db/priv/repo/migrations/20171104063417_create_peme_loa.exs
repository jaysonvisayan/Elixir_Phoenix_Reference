defmodule Innerpeace.Db.Repo.Migrations.CreatePemeLoa do
  use Ecto.Migration

  def change do
    create table(:peme_loas, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :package_id, references(:packages, type: :binary_id, on_delete: :delete_all)
      add :member_id, references(:members, type: :binary_id, on_delete: :delete_all)
      add :peme_date, :date

      timestamps()
    end
    create index(:peme_loas, [:package_id])
    create index(:peme_loas, [:member_id])
  end
end
