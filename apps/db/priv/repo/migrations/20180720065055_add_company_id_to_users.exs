defmodule Innerpeace.Db.Repo.Migrations.AddCompanyIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :company_id, references(:companies, type: :binary_id)
    end
  end
end
