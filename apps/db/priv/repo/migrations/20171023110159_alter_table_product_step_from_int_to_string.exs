defmodule Innerpeace.Db.Repo.Migrations.AlterTableProductStepFromIntToString do
  use Ecto.Migration

  def change do
    alter table(:products) do
      modify :step, :string
    end
  end
end
