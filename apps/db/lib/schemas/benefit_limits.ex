defmodule Innerpeace.Db.Schemas.BenefitLimit do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :coverages,
    :limit_type
  ]}

  schema "benefit_limits" do
    belongs_to :benefit, Innerpeace.Db.Schemas.Benefit
    field :limit_type, :string
    field :limit_percentage, :integer
    field :limit_amount, :decimal
    field :limit_session, :integer
    field :coverages, :string
    field :limit_classification, :string
    field :created_by_id, :binary_id
    field :updated_by_id, :binary_id
    field :limit_tooth, :integer
    field :limit_quadrant, :integer
    field :limit_area_type, {:array, :string}
    field :limit_area, {:array, :string}

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :benefit_id,
      :limit_type,
      :limit_percentage,
      :limit_amount,
      :limit_session,
      :limit_tooth,
      :limit_quadrant,
      :coverages,
      :limit_classification,
      :created_by_id,
      :updated_by_id
    ])
    |> validate_required([
      :benefit_id,
      :limit_type,
      :coverages
    ])
    |> validate_inclusion(:limit_type, [
      "Plan Limit Percentage",
      "Peso",
      "Sessions",
      "Tooth",
      "Quadrant"
    ])
  end

  def changeset_sap_dental(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :benefit_id,
      :limit_type,
      :limit_amount,
      :limit_session,
      :limit_area,
      :limit_area_type,
      :coverages,
      :created_by_id,
      :updated_by_id
    ])
    |> validate_required([
      :benefit_id,
      :limit_type,
      :coverages
    ])
    |> validate_inclusion(:limit_type, ["Peso", "Session", "Tooth", "Area"])
  end

#   def changeset_dental_type_peso(struct, params \\ %{}) do
#     struct
#     |> cast(params, [
#       :benefit_id,
#       :limit_type,
#       :limit_amount,
#       :coverages,
#       :created_by_id,
#       :updated_by_id
#     ])
#     |>
#   end

end
