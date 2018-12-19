defmodule Innerpeace.Db.Schemas.ProductConditionHierarchyOfEligibleDependent do
  use Innerpeace.Db.Schema

  schema "product_condition_hierarchy_of_eligible_dependents" do
    belongs_to :product, Innerpeace.Db.Schemas.Product

    field :hierarchy_type, :string
    field :dependent, :string
    field :ranking, :integer

    timestamps()
  end

  @doc """
  builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :product_id,
      :hierarchy_type,
      :dependent,
      :ranking
    ])
    |> validate_required([
      :product_id,
      :hierarchy_type,
      :dependent,
      :ranking
    ])
  end

end
