defmodule Innerpeace.Db.Schemas.Translation do
  use Innerpeace.Db.Schema

  schema "translations" do
    field :base_value, :string
    field :translated_value, :string
    field :language, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :base_value,
      :translated_value,
      :language
    ])
    |> validate_required([
      :base_value,
      :translated_value,
      :language
    ])
  end
end
