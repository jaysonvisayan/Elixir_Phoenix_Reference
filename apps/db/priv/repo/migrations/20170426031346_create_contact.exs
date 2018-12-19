defmodule Innerpeace.Db.Repo.Migrations.CreateContact do
  use Ecto.Migration

  def change do
    create table(:contacts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :first_name, :string
      add :last_name, :string
      add :type, :string
      add :email, :string
      add :ctc, :string
      add :ctc_date_issued, :date
      add :ctc_place_issued, :string
      add :designation, :string
      add :passport_no, :string
      add :passport_date_issued, :date
      add :passport_place_issued, :string

      timestamps()
    end
  end
end
