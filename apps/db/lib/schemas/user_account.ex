defmodule Innerpeace.Db.Schemas.UserAccount do
  use Innerpeace.Db.Schema

  schema "user_accounts" do
    belongs_to :user, Innerpeace.Db.Schemas.User
    belongs_to :account_group, Innerpeace.Db.Schemas.AccountGroup
    field :role, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :account_group_id, :role])
  end
end
