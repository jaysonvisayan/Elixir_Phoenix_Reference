defmodule Innerpeace.Db.Schemas.Embedded.Emergency do
  use Innerpeace.Db.Schema

  embedded_schema do
    field :admission_datetime, Ecto.Date
    field :chief_complaint
    field :practitioner_id
    field :diagnosis_procedure, {:array, :map}
    field :ruv_ids, {:array, :string}
    field :member_id
    field :facility_id
    field :procedure_fee
    field :payor_pays
    field :member_pays
    field :philhealth_pays, {:array, :string}
    field :user_id
    field :card_number
    field :availment_type
    field :authorization_id
    field :special_approval
    field :internal_remarks
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :admission_datetime,
      :chief_complaint,
      :practitioner_id,
      :member_id,
      :facility_id,
      :procedure_fee,
      :payor_pays,
      :member_pays,
      :user_id,
      :diagnosis_procedure,
      :philhealth_pays,
      :authorization_id,
      :ruv_ids,
      :special_approval,
      :internal_remarks
    ])
    |> validate_required([
      :admission_datetime,
      :practitioner_id,
      :member_id,
      :facility_id
    ])
  end

  def changeset_without_procedure_and_dignosis(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :admission_datetime,
      :chief_complaint,
      :member_id,
      :card_number,
      :practitioner_id,
      :facility_id,
      :availment_type,
      :authorization_id,
      :special_approval,
      :internal_remarks
    ])
    |> validate_required([
      :admission_datetime,
      :chief_complaint,
      :member_id,
      :card_number,
      :practitioner_id,
      :facility_id,
      :availment_type
    ])
  end
end
