defmodule Innerpeace.Db.Schemas.ExclusionCondition do
  use Innerpeace.Db.Schema

  schema "exclusion_conditions" do
    field :member_type, :string
    field :diagnosis_type, :string
    field :duration, :integer
    field :inner_limit, :string
    field :inner_limit_amount, :decimal
    field :within_grace_period, :boolean

    belongs_to :exclusion, Innerpeace.Db.Schemas.Exclusion

    timestamps()
  end

  def changeset_api(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :member_type,
      :diagnosis_type,
      :duration,
      :inner_limit,
      :inner_limit_amount,
      :within_grace_period,
      :exclusion_id
    ])
  end

end
