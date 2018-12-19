defmodule Innerpeace.Db.Repo.Migrations.AddLoaFacilitatedAndReimbursementFieldsInBenefit do
  use Ecto.Migration

  def up do
     alter table(:benefits) do
       add :loa_facilitated, :boolean
       add :reimbursement, :boolean
       add :classification, :string
     end
  end

  def down do
     alter table(:benefits) do
       remove :loa_facilitated
       remove :reimbursement
       remove :classification
     end
  end
end
