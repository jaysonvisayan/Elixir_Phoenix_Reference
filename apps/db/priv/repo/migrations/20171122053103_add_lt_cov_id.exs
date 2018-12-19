defmodule Innerpeace.Db.Repo.Migrations.AddLtCovId do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :lt_cov_id, :string
    end
  end
end
