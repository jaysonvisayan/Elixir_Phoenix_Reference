defmodule Innerpeace.Db.Repo.Migrations.AddFieldInUserIsFileUploaded do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_file_uploaded, :boolean, default: false
    end
  end
end
