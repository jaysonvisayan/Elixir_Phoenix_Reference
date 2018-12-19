defmodule Innerpeace.Db.Repo.Migrations.AddCompanyCoveredToAuthorizationAmount do
  use Ecto.Migration

  def change do
    alter table(:authorization_amounts) do
      add :company_covered, :decimal
    end
  end

end
