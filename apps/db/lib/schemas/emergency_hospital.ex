defmodule Innerpeace.Db.Schemas.EmergencyHospital do
  use Innerpeace.Db.Schema

  schema "emergency_hospitals" do
    field :name, :string
    field :phone, :string
    field :hmo, :string
    field :card_number, :integer
    field :policy_number, :integer
    field :customer_care_number, :integer
    belongs_to :member, Innerpeace.Db.Schemas.Member

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:member_id, :name, :phone, :hmo, :card_number, :policy_number, :customer_care_number])
    |> validate_length(:phone, min: 11, max: 11)
    |> validate_required([:member_id])
  end
end
