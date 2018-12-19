defmodule Innerpeace.Db.Repo.Migrations.ChangeProductDescriptionToText do
  use Ecto.Migration

  def change do
    alter table(:products) do
      modify :description, :text
    end

  end
end
