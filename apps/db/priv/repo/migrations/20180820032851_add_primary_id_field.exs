defmodule Innerpeace.Db.Repo.Migrations.AddPrimaryIdField do
  use Ecto.Migration

  def up do
    alter table(:members) do
      add :primary_id, :string
    end
  end

  def down do
    alter table(:members) do
      remove :primary_id
    end
  end

end
