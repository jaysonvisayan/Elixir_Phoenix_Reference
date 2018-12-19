defmodule Innerpeace.Db.Repo.Migrations.CreateBenefitMiscellaneous do
  use Ecto.Migration

  def up do
    create table(:benefit_miscellaneous, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :benefit_id, references(:benefits, type: :binary_id, on_delete: :delete_all)
      add :miscellaneous_id, references(:miscellaneous, type: :binary_id, on_delete: :delete_all)
      ## cloning purpose
      add :code, :string
      add :description, :string
      add :price, :decimal

      timestamps()
    end
    create index(:benefit_miscellaneous, [:benefit_id])
    create index(:benefit_miscellaneous, [:miscellaneous_id])
  end

  def down do
    drop table(:benefit_miscellaneous)
  end

end
