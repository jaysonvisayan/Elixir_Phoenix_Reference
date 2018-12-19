defmodule Innerpeace.Db.Repo.Migrations.AddNewColumnsToDiagnosis do
  use Ecto.Migration

  def change do
    alter table(:diagnoses) do
      add :group_name, :string
      add :group_code, :string
      add :chapter, :string

      modify :description, :text
      modify :group_description, :text
    end
  end
end
