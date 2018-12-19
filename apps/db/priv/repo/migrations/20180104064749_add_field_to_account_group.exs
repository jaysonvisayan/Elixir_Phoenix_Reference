defmodule Innerpeace.Db.Repo.Migrations.AddFieldToAccountGroup do
  use Ecto.Migration

  def change do
    alter table(:account_groups) do
      add :is_check, :boolean, default: false
    end
  end
end
