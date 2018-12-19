defmodule Innerpeace.Db.Repo.Migrations.AddCancelFieldsToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :cancel_date, :date
      add :cancel_reason, :string
      add :cancel_remarks, :string
    end
  end

end
