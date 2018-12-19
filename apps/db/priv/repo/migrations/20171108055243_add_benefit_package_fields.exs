defmodule Innerpeace.Db.Repo.Migrations.AddBenefitPackageFields do
  use Ecto.Migration

  def change do
  	alter table(:benefit_packages) do
      add :payor_procedure_code, :string
      add :payor_procedure_name, :string
      add :procedure_code, :string
      add :procedure_name, :string
      add :male, :boolean
      add :female, :boolean
      add :age_from, :integer
      add :age_to, :integer
  	end
  end
end
