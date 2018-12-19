defmodule Innerpeace.Db.Schemas.ProductRiskShare do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :fund,
    :af_type,
    :af_value,
    :af_covered,
    :naf_reimbursable,
    :naf_type,
    :naf_value,
    :naf_covered,
    :id
  ]}

  schema "product_risk_shares" do

    belongs_to :product, Innerpeace.Db.Schemas.Product, foreign_key: :product_id
    belongs_to :coverage, Innerpeace.Db.Schemas.Coverage, foreign_key: :coverage_id

    field :fund, :string
    field :af_type, :string
    field :af_value, :integer
    field :af_covered, :integer
    field :naf_reimbursable, :string
    field :naf_type, :string
    field :naf_value, :integer
    field :naf_covered, :integer

    has_many :product_risk_shares_facilities, Innerpeace.Db.Schemas.ProductRiskShareFacility, on_delete: :delete_all

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_id,
      :coverage_id,
      :fund,
      :af_type,
      :af_value,
      :af_covered,
      :naf_reimbursable,
      :naf_type,
      :naf_value,
      :naf_covered,
    ])
    |> validate_required([
      :product_id,
      :coverage_id,
    ])
  end

  def changeset_update(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_id,
      :coverage_id,
      :fund,
      :af_type,
      :af_value,
      :af_covered,
      :naf_reimbursable,
      :naf_type,
      :naf_value,
      :naf_covered,
    ])
    |> validate_required([
      :product_id,
      :coverage_id,
      #:fund,
      :af_type,
      :af_value,
      :af_covered,
      #:naf_reimbursable,
      :naf_type,
      :naf_value,
      :naf_covered,
    ])
  end
end
