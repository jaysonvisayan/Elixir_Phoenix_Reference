defmodule Innerpeace.Db.Schemas.BenefitPackage do
  @moduledoc """
    Schema and changeset for Benefit Packages
  """

  use Innerpeace.Db.Schema

  schema "benefit_packages" do

    field :payor_procedure_code, :string
    field :payor_procedure_name, :string
    field :procedure_code, :string
    field :procedure_name, :string
    field :male, :boolean
    field :female, :boolean
    field :age_from, :integer
    field :age_to, :integer
    belongs_to :benefit, Innerpeace.Db.Schemas.Benefit
    belongs_to :package, Innerpeace.Db.Schemas.Package

    has_many :benefit_package_payor_procedures, Innerpeace.Db.Schemas.BenefitPackagePayorProcedure,
      on_delete: :delete_all

    timestamps()
  end

  @required_fields ~w(benefit_id package_id)
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :payor_procedure_code,
      :benefit_id,
      :package_id,
      :payor_procedure_code,
      :payor_procedure_name,
      :procedure_code,
      :procedure_name,
      :male,
      :female,
      :age_from,
      :age_to
    ])
    |> validate_required([:benefit_id, :package_id])
    |> assoc_constraint(:benefit)
    |> assoc_constraint(:package)
  end
end
