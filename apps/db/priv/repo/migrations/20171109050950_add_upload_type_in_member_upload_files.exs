defmodule Innerpeace.Db.Repo.Migrations.AddUploadTypeInMemberUploadFiles do
  use Ecto.Migration

  def change do
    alter table(:member_upload_files) do
      add :upload_type, :string
    end
  end
end
