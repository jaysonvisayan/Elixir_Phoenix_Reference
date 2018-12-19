defmodule :"Elixir.Innerpeace.Db.Repo.Migrations.Add facialImage column" do
  use Ecto.Migration

  def up do
    alter table(:authorizations) do
      add :facial_image, :string
    end
  end

  def down do
    alter table(:authorizations) do
      remove :facial_image
    end
  end
  
end
