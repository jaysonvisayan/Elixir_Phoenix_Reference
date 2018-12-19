defmodule Innerpeace.Db.Repo.Migrations.AddColumnRequestedBy do
  use Ecto.Migration

  def up do
    alter table(:authorizations) do
      add :requested_by, :string
    end
  end

  def down do
    alter table(:authorizations) do
      remove :requested_by
    end
  end

end
