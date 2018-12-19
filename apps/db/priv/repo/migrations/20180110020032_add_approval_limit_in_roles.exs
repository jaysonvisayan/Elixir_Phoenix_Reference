defmodule Innerpeace.Db.Repo.Migrations.AddApprovalLimitInRoles do
  use Ecto.Migration

  def up do
    alter table(:roles) do
      add :approval_limit, :decimal
    end
  end

  def down do
    alter table(:roles) do
      remove :approval_limit
    end
  end
end
