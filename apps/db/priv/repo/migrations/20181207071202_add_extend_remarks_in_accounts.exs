defmodule Innerpeace.Db.Repo.Migrations.AddExtendRemarksInAccounts do
  use Ecto.Migration

  def up do
    alter table(:accounts) do
      add :extend_remarks, :string
    end
  end

  def down do
    alter table(:accounts) do
      remove :extend_remarks
    end
  end
end
