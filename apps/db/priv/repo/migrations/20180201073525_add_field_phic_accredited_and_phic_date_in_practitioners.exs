defmodule Innerpeace.Db.Repo.Migrations.AddFieldPhicAccreditedAndPhicDateInPractitioners do
  use Ecto.Migration

  def change do
  	alter table(:practitioners) do
      add :phic_accredited, :string
      add :phic_date, :date
    end
  end
end
