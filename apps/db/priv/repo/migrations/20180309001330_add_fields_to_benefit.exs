defmodule Innerpeace.Db.Repo.Migrations.AddFieldsToBenefit do
  use Ecto.Migration

  def change do
    alter table(:benefits) do
      add :covered_enrollees, :string
      add :waiting_period, :string
    end
  end
end
