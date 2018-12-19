defmodule Innerpeace.Db.Repo.Migrations.AddSeniorAndPwdAmount do
  use Ecto.Migration

  def change do
    alter table(:authorization_amounts) do
      add :senior_discount, :decimal
      add :pwd_discount, :decimal
    end

  end
end
