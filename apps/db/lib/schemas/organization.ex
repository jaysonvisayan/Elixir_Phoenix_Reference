defmodule Innerpeace.Db.Schemas.Organization do
  use Innerpeace.Db.Schema

  schema "organizations" do
    field :name, :string

    has_one :account, Innerpeace.Db.Schemas.Account
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
