defmodule Innerpeace.Db.Repo.Migrations.DropUniqueMemberEmail do
  use Ecto.Migration

  def change do
    drop unique_index(:members, [:email])
    drop unique_index(:members, [:mobile])
  end
end
