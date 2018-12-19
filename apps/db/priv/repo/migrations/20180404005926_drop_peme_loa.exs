defmodule Innerpeace.Db.Repo.Migrations.DropPemeLoa do
  use Ecto.Migration

  def change do
    drop table(:peme_loas)
  end
end
