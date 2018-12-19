defmodule Innerpeace.Db.Repo.Migrations.ChangeExclusionNameType do
  use Ecto.Migration

  def change do
    alter table(:exclusions) do
      modify :name, :text
    end
  end
end
