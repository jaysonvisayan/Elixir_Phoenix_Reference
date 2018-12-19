defmodule Innerpeace.Db.Repo.Migrations.AdditionalColumnForProductTblRelatedToStep5condition do
  use Ecto.Migration

  def up do
    alter table(:products) do
      add :no_days_valid, :integer
      add :is_medina, :boolean
      add :smp_limit, :decimal
    end
  end

  def down do
    alter table(:products) do
      remove(:no_days_valid)
      remove(:is_medina)
      remove(:smp_limit)
    end
  end

end
