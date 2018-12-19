defmodule Innerpeace.Db.Schemas.Specialization do
  use Innerpeace.Db.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @derive {Poison.Encoder, only: [
    :name,
    :type
  ]}

  @timestamps_opts [usec: false]
  schema "specializations" do
    field :name, :string
    field :type, :string

    timestamps()

    has_many :practitioner_specializations, Innerpeace.Db.Schemas.PractitionerSpecialization, on_delete: :delete_all
    many_to_many :practitioners, Innerpeace.Db.Schemas.Practitioner, join_through: "practitioner_specializations"
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :type])
    |> validate_required([:name])
  end
end
