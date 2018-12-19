defmodule Innerpeace.Db.Repo.Migrations.AddFieldToBenefit do
  use Ecto.Migration

  def change do
    alter table(:benefits) do
      add :disabled_date, :date
      add :status, :string
    end
  end
end
