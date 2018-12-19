defmodule Innerpeace.Db.Repo.Migrations.ChangeDataTypeMemberUploadLog do
  use Ecto.Migration

  def change do
    alter table(:member_upload_logs) do
      remove (:first_name)
      remove (:middle_name)
      remove (:last_name)
      remove (:suffix)
      add :first_name, :text
      add :middle_name, :text
      add :last_name, :text
      add :suffix, :text
    end

  end
end
