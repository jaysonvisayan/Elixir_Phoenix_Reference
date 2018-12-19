defmodule Innerpeace.Db.Schemas.Company do
  @moduledoc """
  """
  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Poison.Encoder, only: [
    :id,
    :code,
    :name
  ]}
  @timestamps_opts [usec: false]
  schema "companies" do
    field :code, :string
    field :name, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name
    ])
    |> validate_required([
      :code,
      :name
      ])
     |> unique_constraint(:code, message: "Company Code already exist!")
  end

  
end