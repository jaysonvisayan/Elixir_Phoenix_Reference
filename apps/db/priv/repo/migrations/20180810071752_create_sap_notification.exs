defmodule Innerpeace.Db.Repo.Migrations.CreateSapNotification do
  use Ecto.Migration

  def change do
    create table(:sap_notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :migration_notification_id, references(:migration_notifications, type: :binary_id, on_delete: :delete_all)
      add :code, :string
      add :message, :text
      add :status_code, :string
      add :response, :string
      add :response_details, :text

      timestamps()
    end
    create index(:sap_notifications, [:migration_notification_id])
  end
end
