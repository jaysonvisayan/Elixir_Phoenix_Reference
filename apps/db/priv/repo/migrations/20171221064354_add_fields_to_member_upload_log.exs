defmodule Innerpeace.Db.Repo.Migrations.AddFieldsToMemberUploadLog do
  use Ecto.Migration

  def change do
    alter table(:member_upload_logs) do
      add :card_no, :string
      add :policy_no, :string
    end
  end
end
