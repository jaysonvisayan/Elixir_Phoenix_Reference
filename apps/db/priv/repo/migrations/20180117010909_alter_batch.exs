defmodule Innerpeace.Db.Repo.Migrations.AlterBatch do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      remove (:name)
      add :type, :string
      add :coverage, :string
    end
  end
end
