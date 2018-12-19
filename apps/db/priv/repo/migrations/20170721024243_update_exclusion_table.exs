defmodule Innerpeace.Db.Repo.Migrations.UpdateExclusionTable do
  use Ecto.Migration

  def change do
    alter table(:exclusions) do
      add :step, :integer
      add :created_by_id, :binary_id
      add :updated_by_id, :binary_id
    end
  end

end
