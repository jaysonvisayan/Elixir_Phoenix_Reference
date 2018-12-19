defmodule Innerpeace.Db.Schemas.PractitionerSpecialization do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
   :specialization
  ]}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @timestamps_opts [usec: false]
  schema "practitioner_specializations" do
    field :type, :string

    belongs_to :practitioner, Innerpeace.Db.Schemas.Practitioner
    belongs_to :specialization, Innerpeace.Db.Schemas.Specialization

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:type, :practitioner_id, :specialization_id])
    |> assoc_constraint(:practitioner)
    |> assoc_constraint(:specialization)
  end
end
