defmodule Innerpeace.Db.Schemas.Embedded.OPConsult do
  use Innerpeace.Db.Schema

  embedded_schema do
    field :consultation_type
    field :chief_complaint
    field :practitioner_specialization_id
    field :diagnosis_id
    field :member_id
    field :facility_id
    field :consultation_fee
    field :payor_pays
    field :member_pays
    field :user_id
    field :authorization_id
    field :origin
    field :chief_complaint_others
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :consultation_type,
      :chief_complaint,
      :diagnosis_id,
      :member_id,
      :facility_id,
      :consultation_fee,
      :payor_pays,
      :member_pays,
      :user_id,
      :authorization_id,
      :practitioner_specialization_id,
      :origin,
      :chief_complaint_others
    ])
    |> validate_required([
      :consultation_type,
      :chief_complaint,
      :practitioner_specialization_id,
      :diagnosis_id,
      :member_id,
      :facility_id,
    ])
  end
end
