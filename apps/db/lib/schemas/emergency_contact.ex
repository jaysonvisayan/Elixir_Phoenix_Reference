defmodule Innerpeace.Db.Schemas.EmergencyContact do
  use Innerpeace.Db.Schema

  schema "emergency_contact" do
    # ECP = EMERGENCY CONTACT PERSON
    field :ecp_name, :string
    field :ecp_relationship, :string
    field :ecp_phone, :string
    field :ecp_phone2, :string
    field :ecp_email, :string

    field :hospital_name, :string
    field :hospital_telephone, :string

    field :hmo_name, :string
    field :member_name, :string
    field :card_number, :string
    field :policy_number, :string
    field :customer_care_number, :string

    belongs_to :member, Innerpeace.Db.Schemas.Member
    belongs_to :created_by, Innerpeace.Db.Schemas.User,
      foreign_key: :created_by_id
    belongs_to :updated_by, Innerpeace.Db.Schemas.User,
      foreign_key: :updated_by_id

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :member_id,
      :ecp_name,
      :ecp_relationship,
      :ecp_phone,
      :ecp_phone2,
      :ecp_email,
      :hospital_name,
      :hospital_telephone,
      :hmo_name,
      :member_name,
      :card_number,
      :policy_number,
      :customer_care_number
    ])
    |> validate_required([:member_id])
  end
end
