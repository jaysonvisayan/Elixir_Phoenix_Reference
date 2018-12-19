defmodule Innerpeace.Db.Repo.Migrations.ModifySeniorPwdBooleanDefaultFalse do
  use Ecto.Migration

  def change do
    alter table(:members) do
      modify :senior, :boolean, default: false
      modify :pwd, :boolean, default: false
    end
  end
end
