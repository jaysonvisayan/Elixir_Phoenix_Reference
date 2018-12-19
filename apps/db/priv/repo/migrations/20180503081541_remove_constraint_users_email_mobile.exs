defmodule Innerpeace.Db.Repo.Migrations.RemoveConstraintUsersEmailMobile do
  use Ecto.Migration

  def change do
    drop unique_index(:users, [:email])
    drop unique_index(:users, [:mobile])
  end
end
