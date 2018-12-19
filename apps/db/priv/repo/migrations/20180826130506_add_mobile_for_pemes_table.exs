defmodule Innerpeace.Db.Repo.Migrations.AddMobileForPemesTable do
  use Ecto.Migration

  def change do
   alter table(:pemes) do
    add :mobile_number, :string
   end
  end
end
