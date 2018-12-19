defmodule Innerpeace.Db.Repo.Migrations.AddSuspendDateToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :suspend_date, :date
      add :suspend_reason, :string
      add :suspend_remarks, :string
    end
  end

end
