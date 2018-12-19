defmodule Innerpeace.Db.Schemas.Embedded.PackageEmbed do
  use Innerpeace.Db.Schema

  embedded_schema do
    field :code
    field :name
    field :package_id
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :package_id

    ])
    |> validate_required([
      :code,
      :name,
      :package_id
    ])
  end
end
