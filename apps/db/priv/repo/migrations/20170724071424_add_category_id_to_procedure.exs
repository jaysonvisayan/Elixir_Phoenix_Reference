defmodule Innerpeace.Db.Repo.Migrations.AddCategoryIdToProcedure do
  use Ecto.Migration

  def change do
    alter table(:procedures) do
      remove :name
      add :description, :string
      add :procedure_category_id, references(:procedure_categories, type: :binary_id, on_delete: :delete_all)
    end
    create index(:procedures, [:procedure_category_id])
  end
end
