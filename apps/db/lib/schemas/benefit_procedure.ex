defmodule Innerpeace.Db.Schemas.BenefitProcedure do
  use Innerpeace.Db.Schema

  schema "benefit_procedures" do
    belongs_to :benefit, Innerpeace.Db.Schemas.Benefit
    belongs_to :procedure, Innerpeace.Db.Schemas.PayorProcedure
    belongs_to :package, Innerpeace.Db.Schemas.Package
    field :gender, :string
    field :age_from, :integer
    field :age_to, :integer

    timestamps()
  end

  @required_fields ~w(benefit_id procedure_id)
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :benefit_id,
      :procedure_id,
      :gender,
      :age_from,
      :age_to
    ])
    |> validate_required([:benefit_id, :procedure_id])
    |> assoc_constraint(:benefit)
    |> assoc_constraint(:procedure)
  end

  def changeset_acu(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :benefit_id,
      :package_id,
      :procedure_id,
      :gender,
      :age_from,
      :age_to
    ])
    |> validate_required([
      :benefit_id,
      :procedure_id,
      :gender,
      :age_from,
      :age_to
    ])
    |> assoc_constraint(:benefit)
    |> assoc_constraint(:procedure)
    |> validate_inclusion(:gender, ["Male", "Female", "Male & Female"])
    |> validate_age_range()
  end

  defp validate_age_range(changeset) do
    age_from = get_field(changeset, :age_from)
    age_to = get_field(changeset, :age_to)
    if age_from > age_to do
      add_error(changeset, :age_to, "Invalid age range!")
    else
      changeset
    end
  end

end
