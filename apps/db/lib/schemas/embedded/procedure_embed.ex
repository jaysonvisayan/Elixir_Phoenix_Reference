defmodule Innerpeace.Db.Schemas.Embedded.ProcedureEmbed do
  use Innerpeace.Db.Schema

  embedded_schema do
    field :code
    field :type
    field :description
    field :procedure_id
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :procedure_id,
      :type,
      :description
    ])
    |> validate_required([
      :code,
      :name,
      :procedure_id
    ])
  end
end
