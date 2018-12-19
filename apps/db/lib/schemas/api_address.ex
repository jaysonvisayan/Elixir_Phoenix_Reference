defmodule Innerpeace.Db.Schemas.ApiAddress do
  @moduledoc false

  use Innerpeace.Db.Schema

  schema "api_addresses" do
    field :name, :string
    field :address, :string
    field :username, :string
    field :password, :string
    field :token, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :address,
      :username,
      :password,
      :token
    ])
    |> validate_required([
      :name,
      :address,
      :username,
      :password
    ])
  end
end
