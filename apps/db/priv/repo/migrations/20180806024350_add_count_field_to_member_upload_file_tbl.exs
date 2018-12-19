defmodule Innerpeace.Db.Repo.Migrations.AddCountFieldToMemberUploadFileTbl do
  use Ecto.Migration

  def up do
    alter table(:member_upload_files) do
      add :count, :integer
    end
  end

  def down do
    alter table(:member_upload_files) do
      remove :count
    end
  end
end
