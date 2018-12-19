defmodule Innerpeace.Db.Repo.Migrations.AlterBenefitTableAddFieldType do
  use Ecto.Migration

  def up do
     alter table(:benefits) do
       add :type, :string
     end
  end

  def down do
     alter table(:benefits) do
       remove :type
     end
  end
end
