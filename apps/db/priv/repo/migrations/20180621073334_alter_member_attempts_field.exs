defmodule Innerpeace.Db.Repo.Migrations.AlterMemberAttemptsField do
  use Ecto.Migration

  def up do
    alter table(:members) do
      modify :attempts, :integer, default: 0
    end
  end

  def down do
    alter table(:members) do
      modify :attempts, :integer
    end
  end
end
