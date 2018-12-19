defmodule Innerpeace.Db.Repo.Migrations.AddImageUploadInFile do
  use Ecto.Migration

  def change do
    alter table(:files) do
      add :image_type, :string
    end
  end
end
