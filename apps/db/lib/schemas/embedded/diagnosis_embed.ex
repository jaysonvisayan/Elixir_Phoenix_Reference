defmodule Innerpeace.Db.Schemas.Embedded.DiagnosisEmbed do
  use Innerpeace.Db.Schema

  embedded_schema do
    field :code
    field :name
    field :classification
    field :type
    field :group_description
    field :description
    field :congenital
    field :group_code
    field :diagnosis_id
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :code,
      :name,
      :diagnosis_id,
      :type,
      :classification,
      :group_description,
      :description,
      :congenital,
      :package_id,
      :group_code,

    ])
    |> validate_required([
      :code,
      :name,
      :diagnosis_id
    ])
  end
end
