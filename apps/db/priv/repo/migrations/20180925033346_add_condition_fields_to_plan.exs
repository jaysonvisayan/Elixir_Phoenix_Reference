defmodule Innerpeace.Db.Repo.Migrations.AddConditionFieldsToPlan do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :mode_of_payment, :string
      add :availment_type, :string
      add :capitation_type, :string
      add :capitation_fee, :decimal
    end
  end
end
