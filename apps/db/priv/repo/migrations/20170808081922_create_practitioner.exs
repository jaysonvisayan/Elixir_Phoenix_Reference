defmodule Innerpeace.Db.Repo.Migrations.CreatePractitioner do
  use Ecto.Migration

  def change do
    create table(:practitioners, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :first_name, :string
      add :middle_name, :string
      add :last_name, :string
      add :birth_date, :date
      add :effectivity_from, :date
      add :effectivity_to, :date
      add :suffix, :string
      add :gender, :string
      add :affiliated, :string
      add :prc_no, :string
      add :type, {:array, :string}
      add :step, :integer
      add :code, :string
      add :status, :string
      add :photo, :string

      timestamps()
    end
  end
end
