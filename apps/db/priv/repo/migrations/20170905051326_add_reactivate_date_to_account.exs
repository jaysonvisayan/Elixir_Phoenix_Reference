defmodule Innerpeace.Db.Repo.Migrations.AddReactivateDateToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :reactivate_date, :date
      add :reactivate_remarks, :string
    end
  end

end
