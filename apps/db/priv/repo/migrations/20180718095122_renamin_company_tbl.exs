defmodule Innerpeace.Db.Repo.Migrations.RenaminCompanyTbl do
  use Ecto.Migration

  def up do
    rename table(:companies), :company_name, to: :name
    rename table(:companies), :company_code, to: :code
  end

  def down do
    rename table(:companies), :name, to: :company_name
    rename table(:companies), :code, to: :company_code
  end
end
