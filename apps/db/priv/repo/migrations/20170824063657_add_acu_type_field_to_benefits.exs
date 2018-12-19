defmodule Innerpeace.Db.Repo.Migrations.AddAcuTypeFieldInBenefits do
  use Ecto.Migration

  def change do
    alter table(:benefits) do
      add :acu_type, :string
      add :provider_access, :string
  	end
  end
end
