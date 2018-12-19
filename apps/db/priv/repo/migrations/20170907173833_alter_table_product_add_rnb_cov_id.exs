defmodule Innerpeace.Db.Repo.Migrations.AlterTableProductAddRnbCovId do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :rnb_cov_id, :string
    end
  end
end
