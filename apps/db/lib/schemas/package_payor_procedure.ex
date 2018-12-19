defmodule Innerpeace.Db.Schemas.PackagePayorProcedure do
  @moduledoc false

  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Poison.Encoder, only: [
    :id,
    :male,
    :female,
    :age_from,
    :age_to
  ]}

  @timestamps_opts [usec: false]
  schema "package_payor_procedures" do
    field :male, :boolean, default: false
    field :female, :boolean, default: false
    field :age_from, :integer
    field :age_to, :integer

    belongs_to :package, Innerpeace.Db.Schemas.Package
    belongs_to :payor_procedure, Innerpeace.Db.Schemas.PayorProcedure
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :package_id,
      :payor_procedure_id,
      :male,
      :female,
      :age_from,
      :age_to
    ])
    |> validate_required([:payor_procedure_id])
  end
end
