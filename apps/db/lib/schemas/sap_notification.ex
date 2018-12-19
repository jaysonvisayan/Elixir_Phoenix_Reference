defmodule Innerpeace.Db.Schemas.SAPNotification do
    use Innerpeace.Db.Schema
  
    schema "sap_notifications" do
      field :code, :string
      field :message, :string
      field :status_code, :string
      field :response, :string
      field :response_details, :string
      belongs_to :migration_notifications, Innerpeace.Db.Schemas.MigrationNotification, foreign_key: :migration_notification_id
  
      timestamps()
    end
  
    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [
        :code,
        :message,
        :status_code,
        :migration_notification_id,
        :response,
        :response_details
      ])
      |> validate_required([
        :code,
        :message,
        :status_code,
        :response,
        :response_details
      ])
    end
  end
  