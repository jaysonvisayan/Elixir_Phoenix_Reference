defmodule Innerpeace.Db.Schemas.BenefitPackagePayorProcedure do
  @moduledoc """
    Schema and changeset for Benefit Packages
  """

  use Innerpeace.Db.Schema

  schema "benefit_package_payor_procedures" do
    belongs_to :benefit_package, Innerpeace.Db.Schemas.BenefitPackage
    belongs_to :payor_procedure, Innerpeace.Db.Schemas.PayorProcedure, foreign_key: :payor_procedure_id

    timestamps()
  end

  @required_fields ~w(benefit_package_id payor_procedure_id)
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required([:benefit_package_id, :payor_procedure_id])
    |> assoc_constraint(:benefit_package)
    |> assoc_constraint(:payor_procedure)
  end
end
