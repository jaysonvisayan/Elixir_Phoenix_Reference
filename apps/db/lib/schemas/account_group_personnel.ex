defmodule Innerpeace.Db.Schemas.AccountGroupPersonnel do
  use Innerpeace.Db.Schema

  schema "account_group_personnels" do
    field :personnel, :string
    field :specialization, :string
    field :location, :string
    field :schedule, :string
    field :no_of_personnel, :integer
    field :payment_of_mode, :string
    field :retainer_fee, :string
    field :amount, :integer

    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :personnel,
      :specialization,
      :location,
      :schedule,
      :no_of_personnel,
      :payment_of_mode,
      :retainer_fee,
      :amount
    ])
  end

end
