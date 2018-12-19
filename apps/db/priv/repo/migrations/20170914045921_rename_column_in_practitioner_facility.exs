defmodule Innerpeace.Db.Repo.Migrations.RenameColumnInPractitionerFacility do
  use Ecto.Migration

  def change do
    rename table(:practitioner_facilities), :accreditation_date, to: :affiliation_date
    rename table(:practitioner_facilities), :disaccreditation_date, to: :disaffiliation_date
  end
end
