defmodule Innerpeace.Db.Schemas.AccountGroupApproval do
  use Innerpeace.Db.Schema

  schema "account_group_approvals" do
    field :name, :string
    field :department, :string
    field :designation, :string
    field :telephone, :string
    field :mobile, :string
    field :email, :string

    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :account_group_id,
      :name,
      :department,
      :designation,
      :telephone,
      :mobile,
      :email
    ])
    |> validate_required([
      :account_group_id,
      :name,
      :department,
      :mobile,
      :email
    ])
  end

  def changeset_sap(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :account_group_id,
      :name,
      :department,
      :designation,
      :telephone,
      :mobile,
      :email
    ])
  end

end
