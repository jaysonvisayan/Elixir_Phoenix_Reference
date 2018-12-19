defmodule Innerpeace.Db.Repo.Migrations.AddCutoffTimeAndLoaCondition do
  use Ecto.Migration

  def change do
    alter table(:facilities) do
      add :loa_condition, :boolean, default: false
      add :cutoff_time, :time
    end
  end
end
