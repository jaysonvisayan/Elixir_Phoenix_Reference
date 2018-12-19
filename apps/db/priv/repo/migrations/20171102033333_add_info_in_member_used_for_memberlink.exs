defmodule Innerpeace.Db.Repo.Migrations.AddInfoInMemberUsedForMemberlink do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :blood_type, :string
      add :allergies, :string
      add :medication, :string
    end
  end
end
