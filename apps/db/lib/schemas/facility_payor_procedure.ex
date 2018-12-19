defmodule Innerpeace.Db.Schemas.FacilityPayorProcedure do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :payor_procedure_id,
    :code,
    :name,
    :amount,
    :start_date,
    :id
    # :facility,
    # :facility_payor_procedure_rooms
  ]}

  schema "facility_payor_procedures" do
    field :code, :string # Provider CPT Code
    field :name, :string # Provider CPT Name
    field :amount, :decimal
    field :start_date, Ecto.Date

    belongs_to :facility, Innerpeace.Db.Schemas.Facility
    belongs_to :payor_procedure, Innerpeace.Db.Schemas.PayorProcedure
    has_many :facility_payor_procedure_rooms, Innerpeace.Db.Schemas.FacilityPayorProcedureRoom

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :facility_id,
      :payor_procedure_id
    ])
    |> validate_required([
      :code,
      :name,
      :facility_id,
      :payor_procedure_id
    ])
  end
end
