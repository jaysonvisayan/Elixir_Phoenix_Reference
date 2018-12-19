defmodule Innerpeace.Db.Repo.Migrations.AddAccountEnrollmentPeriod do
  use Ecto.Migration

  def change do
    alter table(:account_groups) do
      add :principal_enrollment_period, :integer
      add :dependent_enrollment_period, :integer
      add :pep_day_or_month, :string
      add :dep_day_or_month, :string
    end
  end

end
