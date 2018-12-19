defmodule Innerpeace.Db.Repo.Migrations.AddLimitSessionInExclusion do
  use Ecto.Migration

  def change do
    alter table(:exclusions) do
      add :limit_session, :integer
    end
  end
end
