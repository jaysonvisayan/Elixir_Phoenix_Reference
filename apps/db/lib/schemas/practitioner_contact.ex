defmodule Innerpeace.Db.Schemas.PractitionerContact do
  use Innerpeace.Db.Schema

  @derive {Poison.Encoder, only: [
    :contact
  ]}

  schema "practitioner_contacts" do
    field :type, :string
    belongs_to :practitioner, Innerpeace.Db.Schemas.Practitioner
    belongs_to :contact, Innerpeace.Db.Schemas.Contact

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:practitioner_id, :contact_id])
    |> validate_required([:practitioner_id, :contact_id])
  end
end


