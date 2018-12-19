defmodule Innerpeace.Db.Repo.Migrations.AddMaternityTypeFieldInBenefits do
  use Ecto.Migration

  def change do
    alter table(:benefits) do
      add :maternity_type, :string
  	end
  end
end
