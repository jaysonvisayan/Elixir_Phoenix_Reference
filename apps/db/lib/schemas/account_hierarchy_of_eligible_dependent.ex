defmodule Innerpeace.Db.Schemas.AccountHierarchyOfEligibleDependent do
  @moduledoc """
    Schema and changesets for AccountHierarchyOfEligibleDependent
  """
  use Innerpeace.Db.Schema

  schema "account_hierarchy_of_eligible_dependents" do
    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup

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
      :account_group_id,
      :hierarchy_type,
      :dependent,
      :ranking
    ])
    |> validate_required([
      :account_group_id,
      :hierarchy_type,
      :dependent,
      :ranking
    ])
  end

end
