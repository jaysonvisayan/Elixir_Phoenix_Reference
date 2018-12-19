defmodule Innerpeace.Db.Repo.Migrations.CreateBenefit do
  use Ecto.Migration

  def change do
    create table(:benefits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :code, :string
      add :category, :string
      #add :limit_type, :string
      add :created_by_id, :binary_id
      add :updated_by_id, :binary_id
      add :step, :integer

     timestamps()
    end
    create unique_index(:benefits, [:code])
  end
end
