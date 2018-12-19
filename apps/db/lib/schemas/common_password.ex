defmodule Innerpeace.Db.Schemas.CommonPassword do
  use Innerpeace.Db.Schema

  schema "common_passwords" do
    field :password, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:password])
  end
end
