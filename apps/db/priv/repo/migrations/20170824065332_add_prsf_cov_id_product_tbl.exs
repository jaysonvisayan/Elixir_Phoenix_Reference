defmodule Innerpeace.Db.Repo.Migrations.AddPrsfCovIdProductTbl do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :prsf_cov_id, :string
    end
  end
end
