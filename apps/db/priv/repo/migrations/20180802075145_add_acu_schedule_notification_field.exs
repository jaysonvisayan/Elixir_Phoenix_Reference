defmodule Innerpeace.Db.Repo.Migrations.AddAcuScheduleNotificationField do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :acu_schedule_notification, :boolean, default: false
    end
  end

  def down do
    alter table(:users) do
      remove :pii
    end
  end
end
