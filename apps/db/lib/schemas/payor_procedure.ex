defmodule Innerpeace.Db.Schemas.PayorProcedure do
  @moduledoc false

  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :id,
    :code,
    :description,
    :deactivation_date,
    :inserted_at,
    :package_payor_procedures,
    :exclusion_procedures,
    :facility_payor_procedures
  ]}
  schema "payor_procedures" do
    field :code, :string
    field :description, :string
    field :is_active, :boolean
    field :deactivation_date, Ecto.Date
    field :exclusion_type, :string

    belongs_to :procedure, Innerpeace.Db.Schemas.Procedure
    belongs_to :payor, Innerpeace.Db.Schemas.Payor

    has_many :facility_payor_procedures, Innerpeace.Db.Schemas.FacilityPayorProcedure, on_delete: :delete_all
    has_many :package_payor_procedures, Innerpeace.Db.Schemas.PackagePayorProcedure, on_delete: :delete_all
    has_many :procedure_logs, Innerpeace.Db.Schemas.ProcedureLog, on_delete: :delete_all
    has_many :package_logs, Innerpeace.Db.Schemas.PackageLog, on_delete: :delete_all
    has_many :exclusion_procedures,
      Innerpeace.Db.Schemas.ExclusionProcedure,
      on_delete: :delete_all,
      foreign_key: :procedure_id

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :description,
      :procedure_id,
      :payor_id,
      :is_active,
      :deactivation_date,
      :exclusion_type
    ])
    |> validate_required([
      :code,
      :description,
      :procedure_id,
      :payor_id
    ])
    #|> unique_constraint(
    #:code,
    #name: :payor_procedures_is_active_code_index, message: "Payor CPT Code is has already taken")
  end

  def changeset_exclusion_type(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :exclusion_type
    ])
    |> validate_required([
      :exclusion_type
    ])
  end

  def changeset_exclusion_type_nil(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :exclusion_type
    ])
  end

end
