defmodule Innerpeace.Db.Repo.Migrations.AddPayrollCodeToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :payroll_code, :string
    end
  end

end
