defmodule Innerpeace.Db.Repo.Migrations.AddCodeToCoverage do
  use Ecto.Migration

  def change do
    alter table(:coverages) do
      add :code, :string
    end
  end
end
