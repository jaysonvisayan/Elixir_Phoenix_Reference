defmodule Innerpeace.Db.Schemas.Dropdown do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :text,
    :type
  ]}
  schema "dropdowns" do
    field :type, :string
    field :text, :string
    field :value, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :type,
      :text,
      :value

    ])
    |> validate_required([:text])

  end

end
