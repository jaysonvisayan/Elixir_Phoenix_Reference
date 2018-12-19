defmodule Innerpeace.Db.Repo.Migrations.AddPrincipalProductToMember do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :principal_product_id, references(:member_products, type: :binary_id)
    end
  end
end
