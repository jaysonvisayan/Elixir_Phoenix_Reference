defmodule Innerpeace.Db.Repo.Migrations.AddDeleteDateInBenefit do
  use Ecto.Migration

  def change do
    alter table(:benefits) do
      add :delete_date, :date
    end
  end
end
