defmodule Innerpeace.Db.Schemas.FacilityServiceFee do
  use Innerpeace.Db.Schema

  schema "facility_service_fees" do
    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :coverage, Innerpeace.Db.Schemas.Coverage
    belongs_to :service_type, Innerpeace.Db.Schemas.Dropdown, foreign_key: :service_type_id
    field :payment_mode, :string
    field :rate_fixed, :decimal
    field :rate_mdr, :integer

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :facility_id,
      :coverage_id,
      :service_type_id,
      :payment_mode,
      :rate_fixed,
      :rate_mdr
    ])
    |> validate_required([
      :facility_id,
      :coverage_id,
      :service_type_id,
      :payment_mode
    ])
    |> assoc_constraint(:facility)
    |> assoc_constraint(:coverage)
    |> assoc_constraint(:service_type)
  end

end

