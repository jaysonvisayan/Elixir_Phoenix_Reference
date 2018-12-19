defmodule Innerpeace.Db.Repo.Migrations.AddOtherMobileInUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :other_mobile, :string
    end
  end
end
