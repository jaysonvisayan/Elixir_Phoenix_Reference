defmodule Innerpeace.Db.Repo.Migrations.UniqueMemberEmployeeNo do
  use Ecto.Migration

  def change do
    create unique_index(:members, [:account_code, :employee_no])
  end
end
