defmodule Innerpeace.Db.Repo.Migrations.AddMovementFieldsInMembers do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :cancel_date, :date
      add :cancel_reason, :string
      add :cancel_remarks, :string
      add :reactivate_date, :date
      add :reactivate_reason, :string
      add :reactivate_remarks, :string
      add :suspend_date, :date
      add :suspend_reason, :string
      add :suspend_remarks, :string
    end
  end
end
