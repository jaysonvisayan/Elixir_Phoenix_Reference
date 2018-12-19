defmodule Innerpeace.Db.Schemas.PractitionerFacilityConsultationFee do
  use Innerpeace.Db.Schema

  schema "practitioner_facility_consultation_fees" do
    belongs_to :practitioner_facility, Innerpeace.Db.Schemas.PractitionerFacility
    belongs_to :practitioner_specialization, Innerpeace.Db.Schemas.PractitionerSpecialization

    field :fee, :decimal
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :practitioner_facility_id,
      :practitioner_specialization_id,
      :fee
    ])
    |> validate_required([
      :practitioner_facility_id,
      :practitioner_specialization_id,
      :fee
    ])
  end
end
