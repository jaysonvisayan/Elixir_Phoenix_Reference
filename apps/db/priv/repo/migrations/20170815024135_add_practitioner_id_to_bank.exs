defmodule Innerpeace.Db.Repo.Migrations.AddPractitionerIdToBank do
  use Ecto.Migration

  def change do
    alter table(:banks) do
      add :practitioner_id, references(:practitioners, type: :binary_id, on_delete: :delete_all)
    end
    create index(:banks, [:practitioner_id])
  end
end
