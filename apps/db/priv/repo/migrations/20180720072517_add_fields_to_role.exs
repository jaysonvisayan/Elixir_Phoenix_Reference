defmodule Innerpeace.Db.Repo.Migrations.AddFieldsToRole do
  use Ecto.Migration

  def up do
    alter table(:roles) do
      add :pii, :boolean, default: false
      add :create_full_access, :string
      add :no_of_days, :integer
      add :cut_off_dates, {:array, :integer}
      add :member_permitted, :boolean, default: false
    end
  end

  def down do
    alter table(:roles) do
      remove :pii
      remove :create_full_access
      remove :no_of_days
      remove :cut_off_dates
      remove :member_permitted
    end
  end

end
