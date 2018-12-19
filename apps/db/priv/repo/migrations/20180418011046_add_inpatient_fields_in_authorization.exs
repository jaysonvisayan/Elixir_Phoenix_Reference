defmodule Innerpeace.Db.Repo.Migrations.AddInpatientFieldsInAuthorization do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add :nature_of_admission, :string
      add :point_of_admission, :string
      add :senior_discount, :decimal
      add :pwd_discount, :decimal
      add :date_issued, :date
      add :place_issued, :string
      add :or_and_dr_fee, :decimal
    end
  end
end
